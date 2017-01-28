port module API exposing (..)

import Cors exposing (..)
import Http
import Json.Decode exposing (Decoder, list, string)
import Json.Decode.Pipeline exposing (required, decode, hardcoded)
import Quote exposing (..)
import Route exposing (..)
import Serverless
import Serverless.Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Plug as Plug exposing (..)
import Serverless.Route exposing (parseRoute)


{-| A Serverless.Program is parameterized by your 3 custom types

* Config is a server load-time record of deployment specific values
* Model is for whatever you need during the processing of a request
* Msg is your app message type
-}
main : Serverless.Program Config Model Msg
main =
    Serverless.httpApi
        { configDecoder = configDecoder
        , requestPort = requestPort
        , responsePort = responsePort
        , endpoint = Endpoint
        , initialModel = Model []
        , pipeline = pipeline
        , subscriptions = subscriptions
        }



-- MODEL


{-| Serverless.Conn.Conn is short for connection.

It is parameterized by the Config and Model record types.
For convenience we create an alias.
-}
type alias Conn =
    Serverless.Conn.Types.Conn Config Model


{-| Can be anything you want, you just need to provide a decoder
-}
type alias Config =
    { languages : List String
    }


{-| Can be anything you want.
This will get set to initialModel (see above) for each incomming connection.
-}
type alias Model =
    { quotes : List Quote
    }


configDecoder : Json.Decode.Decoder Config
configDecoder =
    decode Config
        |> required "languages" (list string)



-- UPDATE


{-| Your custom message type.

The only restriction is that it has to contain an endpoint. You can call the
endpoint whatever you want, but it accepts no parameters, and must be provided
to the program as `endpoint` (see above).
-}
type Msg
    = Endpoint
    | QuoteResult (Result Http.Error Quote)


{-| Your pipeline.

A pipeline is a sequence of plugs, each of which transforms the connection
in some way.
-}
pipeline : Pipeline Config Model Msg
pipeline =
    Plug.pipeline
        -- Simple plugs just transform the connection.
        -- For example, this cors plug just adds some headers to the response.
        |>
            plug (cors "*" [ GET, OPTIONS ])
        -- After parsing a route, you can apply a router.
        -- A router takes a route and returns a pipeline that will handle that
        -- route. Applying a router when `conn.route` is `Nothing` automatically
        -- responds with a 404.
        |>
            fork router


router : Conn -> Pipeline Config Model Msg
router conn =
    -- Our route parser gives us back nicely structured data, thanks to
    -- evancz/url-route parser (modified for use outside of the browser)
    case conn |> parseRoute route NotFound of
        Home ->
            Plug.pipeline
                |> loop
                    (\msg conn ->
                        conn
                            |> body (TextBody "Home")
                            |> status (Code 200)
                            |> send responsePort
                    )

        Quote lang ->
            Plug.pipeline
                -- Loop pipelines are like elm update functions.
                -- They can be used to wait for the results of side effects.
                -- For example, loadQuotes makes a few http requests and collects the
                -- results in the model.
                --
                -- Notice that we are passing part of the router result
                -- (i.e. `lang`) into `loadQuotes`.
                |>
                    loop (loadQuotes lang)
                -- You can have multiple loop plugs. The last one in the pipeline
                -- must send a respnose, or an internal server error will automatically
                -- be sent by the framework
                |>
                    loop respondWithQuotes

        NotFound ->
            Plug.pipeline
                |> loop
                    (\msg conn ->
                        conn
                            |> status (Code 404)
                            |> body ("404 not found" |> TextBody)
                            |> send responsePort
                    )


langFilter : Route.Lang -> List String -> List String
langFilter filt langs =
    case filt of
        LangAll ->
            langs

        Lang string ->
            if langs |> List.member string then
                [ string ]
            else
                []


loadQuotes : Route.Lang -> Msg -> Conn -> ( Conn, Cmd Msg )
loadQuotes lang msg conn =
    case msg of
        Endpoint ->
            (case conn.config.languages |> langFilter lang of
                [] ->
                    conn
                        |> body (TextBody "Could not find language")
                        |> status (Code 404)
                        |> send responsePort

                langs ->
                    -- Whenever you return a side effect for which you want to
                    -- wait for the response, you should pause the connection.
                    -- In this case, we are going to wait for X http requests (one
                    -- for each supported language), so we increment the pause count
                    -- by X
                    --
                    -- Pausing the connection prevents the pipeline from continuing
                    -- past this plug. At least, until resume reduces the pause count
                    -- back to zero.
                    conn
                        |> pipelinePause
                            (langs |> List.length)
                            (langs
                                |> List.map quoteRequest
                                |> List.map (Http.send QuoteResult)
                                |> Cmd.batch
                            )
                            responsePort
            )

        QuoteResult result ->
            case result of
                Ok q ->
                    conn
                        |> updateModel (\model -> { model | quotes = q :: model.quotes })
                        -- We've got one of our responses now, so we reduce the
                        -- pause count by 1. When all the responses are collected
                        -- our pause count will be zero, and the pipeline will
                        -- automatically continue onto the next plug.
                        --
                        -- The response port is passed because resume will
                        -- automatically send server errors if the pause count
                        -- underflows.
                        -- Try changing the resume count to 3, to see what happens
                        |>
                            pipelineResume 1 responsePort

                Err err ->
                    -- If anything unexpected happends, we can always send a
                    -- response early. Sending a response prevents further plugs
                    -- from processing and removes the connection from the
                    -- connection pool
                    conn
                        |> internalError err responsePort


respondWithQuotes : Msg -> Conn -> ( Conn, Cmd Msg )
respondWithQuotes msg conn =
    case msg of
        -- Each time a plug is processed for the first time, it will get the
        -- endpoint message.
        Endpoint ->
            conn
                |> status (Code 200)
                |> header ( "content-type", "text/html" )
                -- By the time we get here, we can be sure that loadQuotes has
                -- successfully loaded all the quotes, so we can sort, format,
                -- and send them in the response body.
                |>
                    body
                        (conn.model.quotes
                            |> List.sortBy .lang
                            |> List.map (formatQuote "<br/>")
                            |> String.join "<br/><br/>"
                            |> TextBody
                        )
                |> send responsePort

        -- This method only expects Endpoint. If we get anything else, it means
        -- that something is wrong with our pause/resuming count from the previous
        -- plug.
        _ ->
            conn |> unexpectedMsg msg responsePort



-- SUBSCRIPTIONS


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg


subscriptions : Conn -> Sub Msg
subscriptions _ =
    Sub.none
