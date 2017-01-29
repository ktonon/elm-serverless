module API exposing (..)

import Middleware.Cors exposing (..)
import Pipelines.Quote as Quote
import Route exposing (..)
import Serverless
import Serverless.Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Plug as Plug exposing (..)
import Serverless.Route exposing (parseRoute)
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
pipeline : Pipeline
pipeline =
    Plug.pipeline
        -- Simple plugs just transform the connection.
        -- For example, this cors plug just adds some headers to the response.
        |>
            plug (cors "*" [ GET, OPTIONS ])
        -- A router takes a `Conn` and returns a new pipeline.
        |>
            fork router


router : Conn -> Pipeline
router conn =
    -- This router parses `conn.req.path` into elm data thanks to
    -- evancz/url-parser (modified for use outside of the browser).
    -- We can then match on the HTTP method and route, returning custom
    -- pipelines for each combination.
    case ( conn.req.method, conn |> parseRoute route NotFound ) of
        ( GET, Home ) ->
            status (Code 200)
                >> body (TextBody "Home")
                >> send responsePort
                |> toPipeline

        ( GET, Quote lang ) ->
            -- Notice that we are passing part of the router result
            -- (i.e. `lang`) into `loadQuotes`.
            Quote.pipeline lang

        _ ->
            status (Code 404)
                >> body (TextBody "Nothing here")
                >> send responsePort
                |> toPipeline



-- SUBSCRIPTIONS


subscriptions : Conn -> Sub Msg
subscriptions _ =
    Sub.none
