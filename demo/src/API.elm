module API exposing (..)

import Pipelines.Quote as Quote
import Route exposing (..)
import Serverless exposing (..)
import Serverless.Conn as Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Cors exposing (cors)
import Types exposing (..)


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


{-| Your pipeline.

A pipeline is a sequence of plugs, each of which transforms the connection
in some way.
-}
pipeline : Plug
pipeline =
    Conn.pipeline
        -- Simple plugs just transform the connection.
        -- For example, this cors plug just adds some headers to the response.
        |>
            plug (\conn -> conn |> cors conn.config.cors)
        -- A router takes a `Conn` and returns a new pipeline.
        |>
            fork router


router : Conn -> Plug
router conn =
    -- This router parses `conn.req.path` into elm data thanks to
    -- evancz/url-parser (modified for use outside of the browser).
    -- We can then match on the HTTP method and route, returning custom
    -- pipelines for each combination.
    case
        ( conn.req.method
        , conn |> parseRoute route NotFound
        )
    of
        ( GET, Home ) ->
            -- toResponder can quickly create a loop plug which sends a response
            statusCode 200
                >> textBody "Home"
                |> toResponder responsePort

        ( _, Quote lang ) ->
            -- Notice that we are passing part of the router result
            -- (i.e. `lang`) into `loadQuotes`.
            Quote.router conn.req.method lang

        ( GET, Buggy ) ->
            internalError (TextBody "bugs, bugs, bugs")
                |> toResponder responsePort

        _ ->
            -- use this form of toResponder when you need to access the conn
            toResponder responsePort <|
                \conn ->
                    conn
                        |> statusCode 404
                        |> textBody ("Nothing at: " ++ conn.req.path)



-- SUBSCRIPTIONS


subscriptions : Conn -> Sub Msg
subscriptions _ =
    Sub.none
