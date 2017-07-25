module Pipelines.Quote exposing (..)

import Http
import Models.Quote as Quote
import Route exposing (..)
import Serverless.Conn as Conn exposing (respond, updateResponse)
import Serverless.Conn.Body as Body exposing (json, text)
import Serverless.Conn.Request as Request exposing (Method(..))
import Serverless.Plug as Plug
import Types exposing (Conn, Plug, Msg(..), responsePort)


router : Method -> Lang -> Plug
router method lang =
    case method of
        GET ->
            get lang

        POST ->
            post lang

        _ ->
            Plug.responder responsePort <|
                \_ -> ( 405, text "Method not allowed" )



-- updateResponse
--     (setStatus (code 405)
--         >> setBody (text utf8 "Method not allowed")
--     )
--     |> Plug.responder responsePort


get : Lang -> Plug
get lang =
    Plug.pipeline
        -- Loop pipelines are like elm update functions.
        -- They can be used to wait for the results of side effects.
        -- For example, loadQuotes makes a few http requests and collects the
        -- results in the model.
        --
        |>
            Plug.loop (loadQuotes lang)
        -- You can have multiple loop plugs. The last one in the pipeline
        -- must send a respnose, or an internal server error will automatically
        -- be sent by the framework
        |>
            Plug.loop respondWithQuotes


post : Lang -> Plug
post lang =
    Plug.responder responsePort <|
        \conn ->
            ( 501
            , text <|
                "Not implemented, but I got this body: "
                    ++ (conn |> Conn.request |> Request.body |> toString)
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
            (case conn |> Conn.config |> .languages |> langFilter lang of
                [] ->
                    respond responsePort ( 404, text "Could not find language" ) conn

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
                        |> Conn.pause
                            (langs |> List.length)
                            (langs
                                |> List.map Quote.request
                                |> List.map (Http.send QuoteResult)
                                |> Cmd.batch
                            )
            )

        QuoteResult result ->
            case result of
                Ok q ->
                    conn
                        |> Conn.updateModel (\model -> { model | quotes = q :: model.quotes })
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
                            Conn.resume 1

                Err err ->
                    -- If anything unexpected happends, we can always send a
                    -- response early. Sending a response prevents further plugs
                    -- from processing and removes the connection from the
                    -- connection pool
                    respond responsePort ( 500, text <| toString err ) conn


respondWithQuotes : Msg -> Conn -> ( Conn, Cmd Msg )
respondWithQuotes msg conn =
    case msg of
        -- Each time a plug is processed for the first time, it will get the
        -- endpoint message.
        Endpoint ->
            -- By the time we get here, we can be sure that loadQuotes has
            -- successfully loaded all the quotes, so we can sort, format,
            -- and send them in the response body.
            respond responsePort
                ( 200
                , conn
                    |> Conn.model
                    |> .quotes
                    |> List.sortBy .lang
                    |> Quote.encodeList
                    |> Body.json
                )
                conn

        -- This method only expects Endpoint. If we get anything else, it means
        -- that something is wrong with our pause/resuming count from the previous
        -- plug.
        _ ->
            respond responsePort
                ( 500
                , text <| (++) "Unexpected message: " <| toString msg
                )
                conn
