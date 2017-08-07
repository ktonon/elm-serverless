module API exposing (..)

import Middleware
import Pipelines.Quote as Quote
import Route exposing (Route(..))
import Serverless exposing (..)
import Serverless.Conn as Conn exposing (method, respond, route, updateResponse)
import Serverless.Conn.Body as Body exposing (text)
import Serverless.Conn.Request as Request exposing (Method(..))
import Serverless.Plug as Plug exposing (Plug, plug)
import Types exposing (..)
import UrlParser


{-| A Serverless.Program is parameterized by your 4 custom types

  - Config is a server load-time record of deployment specific values
  - Model is for whatever you need during the processing of a request
  - Route represents the set of routes your app will handle
  - Msg is your app message type

-}
main : Serverless.Program Config Model Route Msg
main =
    Serverless.httpApi
        { configDecoder = configDecoder
        , requestPort = requestPort
        , responsePort = responsePort
        , endpoint = Endpoint -- Requests will come in with this message
        , initialModel = Model []
        , parseRoute = UrlParser.parseString Route.route
        , update = update
        , subscriptions = subscriptions
        }


pipeline : Plug Config Model Route
pipeline =
    Plug.pipeline
        |> plug Middleware.cors
        |> plug Middleware.auth


{-| The application update function.

Just like an Elm SPA, an elm-serverless app has a single update
function which is the first point of contact for incoming messages.

-}
update : Msg -> Conn -> ( Conn, Cmd Msg )
update msg conn =
    case msg of
        -- New requests come in here
        Endpoint ->
            conn
                -- Calls folds conn into each plug of the pipeline,
                -- until the pipeline is exhausted, or until one of the plugs
                -- "sends" a response
                |> Plug.apply pipeline
                -- mapUnsent only applies the router if the conn is unsent,
                -- otherwise we get `(sentConn, Cmd.none)`. Note that a sent
                -- response is encapsulated in `conn`, not as a command.
                -- Once a conn is sent, it is removed from the connection pool.
                |> Conn.mapUnsent router

        -- This message is intended for the Pipeline/Quote module
        GotQuotes result ->
            Quote.gotQuotes result conn


router : Conn -> ( Conn, Cmd Msg )
router conn =
    case
        ( method conn
        , -- Elm data returned from client provided parseRoute function.
          -- The connection path is parsed before calling the update function,
          -- so by the time you get here, we don't have to worry about handling
          -- unexpected paths, a 404 will be automatically replied if parsing
          -- fails.
          route conn
        )
    of
        ( GET, Home query ) ->
            ( Conn.respond ( 200, text <| (++) "Home: " <| toString query ) conn
            , Cmd.none
            )

        ( _, Quote lang ) ->
            Quote.router lang conn

        ( GET, Buggy ) ->
            ( Conn.respond ( 500, text "bugs, bugs, bugs" ) conn
            , Cmd.none
            )

        _ ->
            ( Conn.respond ( 405, text "Method not allowed" ) conn
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Conn -> Sub Msg
subscriptions _ =
    Sub.none
