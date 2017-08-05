module API exposing (..)

import Dict
import Middleware exposing (cors)
import Pipelines.Quote as Quote
import Route exposing (Route(..))
import Serverless exposing (..)
import Serverless.Conn as Conn exposing (method, respond, route, updateResponse)
import Serverless.Conn.Body as Body exposing (text)
import Serverless.Conn.Request as Request exposing (Method(..))
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
        , parseRoute = \path -> UrlParser.parse Route.route path Dict.empty
        , update = update
        , subscriptions = subscriptions
        }


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
                |> cors
                |> router

        -- This message is intended for the Pipeline/Quote module
        GotQuotes result ->
            Quote.gotQuotes result conn


router : Conn -> ( Conn, Cmd Msg )
router conn =
    case ( method conn, route conn ) of
        ( GET, Home ) ->
            Conn.respond responsePort
                ( 200, text "Home" )
                conn

        ( _, Quote lang ) ->
            Quote.router lang conn

        ( GET, Buggy ) ->
            Conn.respond responsePort
                ( 500, text "bugs, bugs, bugs" )
                conn

        _ ->
            Conn.respond responsePort
                ( 405, text "Method not allowed" )
                conn



-- SUBSCRIPTIONS


subscriptions : Conn -> Sub Msg
subscriptions _ =
    Sub.none
