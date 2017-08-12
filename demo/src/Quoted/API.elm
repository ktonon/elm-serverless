module Quoted.API exposing (..)

import Json.Encode
import Quoted.Middleware
import Quoted.Pipelines.Quote as Quote
import Quoted.Route exposing (Route(..))
import Quoted.Types exposing (..)
import Serverless
import Serverless.Conn exposing (interop, jsonBody, mapUnsent, method, respond, route, textBody, updateResponse)
import Serverless.Conn.Request exposing (Method(..))
import Serverless.Plug as Plug exposing (plug)
import UrlParser


{-| A Serverless.Program is parameterized by your 5 custom types

  - Config is a server load-time record of deployment specific values
  - Model is for whatever you need during the processing of a request
  - Route represents the set of routes your app will handle
  - Interop enumerates the JavaScript functions which may be called
  - Msg is your app message type

-}
main : Serverless.Program Config () Route Interop Msg
main =
    Serverless.httpApi
        { initialModel = ()

        -- Decodes per instance configuration into Elm data. If decoding fails
        -- the server will fail to start. This decoder is called once at
        -- startup.
        , configDecoder = configDecoder

        -- Parses the request path and query string into Elm data.
        -- If parsing fails, a 404 is automatically sent.
        , parseRoute = UrlParser.parseString Quoted.Route.route

        -- Entry point for new connections.
        -- This function composition passes the conn through a pipeline and then
        -- into a router (but only if the conn is not sent by the pipeline).
        , endpoint = Plug.apply pipeline >> mapUnsent router

        -- Update function which operates on Conn.
        , update = update

        -- Enumerates JavaScript interop functions and provides JSON coders
        -- to convert data between Elm and JSON.
        , interop = Serverless.Interop interopEncode interopDecoder

        -- Provides ports to the framework which are used for requests,
        -- responses, and JavaScript interop function calls. Do not use these
        -- ports directly, the framework handles associating messages to
        -- specific connections with unique identifiers.
        , requestPort = requestPort
        , responsePort = responsePort
        }


{-| Pipelines are chains of functions (plugs) which transform the connection.

These pipelines can optionally send a response through the connection early, for
example a 401 sent if authorization fails. Use Plug.apply to pass a connection
through a pipeline (see above). Note that Plug.apply will stop processing the
pipeline once the connection is sent.

-}
pipeline : Plug
pipeline =
    Plug.pipeline
        |> plug Quoted.Middleware.cors
        |> plug Quoted.Middleware.auth


{-| Just a big "case of" on the request method and route.

Remember that route is the request path and query string, already parsed into
nice Elm data, courtesy of the parseRoute function provided above.

-}
router : Conn -> ( Conn, Cmd Msg )
router conn =
    case
        ( method conn
        , route conn
        )
    of
        ( GET, Home query ) ->
            respond ( 200, textBody <| (++) "Home: " <| toString query ) conn

        ( _, Quote lang ) ->
            -- Delegate to Pipeline/Quote module.
            Quote.router lang conn

        ( GET, Number ) ->
            -- This one calls out to a JavaScript function named `getRandom`.
            -- The result comes in as a message `RandomNumber`.
            interop [ GetRandom 1000000000 ] conn

        ( GET, Buggy ) ->
            respond ( 500, textBody "bugs, bugs, bugs" ) conn

        _ ->
            respond ( 405, textBody "Method not allowed" ) conn


{-| The application update function.

Just like an Elm SPA, an elm-serverless app has a single update
function which handles messages resulting from interop calls and side-effects
in general.

-}
update : Msg -> Conn -> ( Conn, Cmd Msg )
update msg conn =
    case msg of
        -- This message is intended for the Pipeline/Quote module
        GotQuotes result ->
            Quote.gotQuotes result conn

        -- Result of a JavaScript interop call. The `interopDecoder` function
        -- passed into Serverless.httpApi is responsible for converting interop
        -- results into application messages.
        RandomNumber val ->
            respond ( 200, jsonBody <| Json.Encode.int val ) conn
