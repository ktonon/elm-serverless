module Serverless.Conn.Request
    exposing
        ( Id
        , Method(..)
        , Request
        , Scheme(..)
        , body
        , decoder
        , endpoint
        , headers
        , id
        , init
        , method
        , methodDecoder
        , path
        , query
        , schemeDecoder
        , stage
        )

{-| Query attributes of the HTTP request.

Typically imported as

    import Serverless.Conn.Request as Request

@docs Request, Id, Method, Scheme


## Attributes

@docs id, body, endpoint, headers, method, path, query, stage


## Misc

These functions are typically not needed when building an application. They are
used internally by the framework.

@docs init, decoder, methodDecoder, schemeDecoder

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required)
import Serverless.Conn.Body as Body exposing (Body)
import Serverless.Conn.IpAddress as IpAddress exposing (IpAddress)
import Serverless.Conn.KeyValueList as KeyValueList


{-| An HTTP request.
-}
type Request
    = Request Model


{-| Universally unique request identifier.
-}
type alias Id =
    String


{-| HTTP request method.

    -- to use shorthand notation
    import Serverless.Conn.Request exposing (Method(..))

-}
type Method
    = CONNECT
    | DELETE
    | GET
    | HEAD
    | OPTIONS
    | PATCH
    | POST
    | PUT
    | TRACE


{-| Request scheme (a.k.a. protocol).

    -- to use shorthand notation
    import Serverless.Conn.Request exposing (Scheme(..))

-}
type Scheme
    = Http
    | Https


type alias Model =
    { id : Id
    , body : Body
    , headers : List ( String, String )
    , host : String
    , method : Method
    , path : String
    , port_ : Int
    , remoteIp : IpAddress
    , scheme : Scheme
    , stage : String
    , queryParams : List ( String, String )
    }



-- CONSTRUCTORS


{-| Initialize an empty Request.

Exposed for unit testing. Incoming connections initialize requests using
JSON decoders.

-}
init : Id -> Request
init id =
    Request
        (Model
            id
            Body.empty
            []
            ""
            GET
            "/"
            80
            IpAddress.loopback
            Http
            "test"
            []
        )



-- GETTERS


{-| Universally unique identifier.
-}
id : Request -> Id
id (Request { id }) =
    id


{-| Request body.
-}
body : Request -> Body
body (Request { body }) =
    body


{-| Describes the server endpoint to which the request was made.

    ( scheme, host, port_ ) =
        Request.endpoint req

  - `scheme` is either `Request.Http` or `Request.Https`
  - `host` is the hostname as taken from the `"host"` request header
  - `port_` is the port, for example `80` or `443`

-}
endpoint : Request -> ( Scheme, String, Int )
endpoint (Request req) =
    ( req.scheme, req.host, req.port_ )


{-| List of key-value pairs representing headers.

Headers are normalized such that the keys are always `lower-case`.

-}
headers : Request -> List ( String, String )
headers (Request { headers }) =
    headers


{-| HTTP request method.

    case Request.method req of
        Request.GET ->
            -- handle get...

        Request.POST ->
            -- handle post...

        _ ->
            -- method not supported...

-}
method : Request -> Method
method (Request { method }) =
    method


{-| Request path.
-}
path : Request -> String
path (Request { path }) =
    path


{-| List of key-value pairs representing query arguments.
-}
query : Request -> List ( String, String )
query (Request { queryParams }) =
    queryParams


{-| IP address of the requesting entity.
-}
remoteIp : Request -> IpAddress
remoteIp (Request { remoteIp }) =
    remoteIp


{-| Serverless deployment stage.

See <https://serverless.com/framework/docs/providers/aws/guide/deploying/>

-}
stage : Request -> String
stage (Request { stage }) =
    stage



-- JSON


{-| JSON decoder for HTTP requests.
-}
decoder : Decoder Request
decoder =
    decode Model
        |> required "id" Decode.string
        |> required "body" Body.decoder
        |> required "headers" KeyValueList.decoder
        |> required "host" Decode.string
        |> required "method" methodDecoder
        |> required "path" Decode.string
        |> required "port" Decode.int
        |> required "remoteIp" IpAddress.decoder
        |> required "scheme" schemeDecoder
        |> required "stage" Decode.string
        |> required "queryParams" KeyValueList.decoder
        |> Decode.map Request


{-| JSON decoder for the HTTP request method.
-}
methodDecoder : Decoder Method
methodDecoder =
    Decode.string
        |> Decode.andThen
            (\w ->
                case w |> String.toLower of
                    "connect" ->
                        Decode.succeed CONNECT

                    "delete" ->
                        Decode.succeed DELETE

                    "get" ->
                        Decode.succeed GET

                    "head" ->
                        Decode.succeed HEAD

                    "options" ->
                        Decode.succeed OPTIONS

                    "patch" ->
                        Decode.succeed PATCH

                    "post" ->
                        Decode.succeed POST

                    "put" ->
                        Decode.succeed PUT

                    "trace" ->
                        Decode.succeed TRACE

                    _ ->
                        Decode.fail ("Unsupported method: " ++ w)
            )


{-| JSON decoder for the request scheme (a.k.a. protocol)
-}
schemeDecoder : Decoder Scheme
schemeDecoder =
    Decode.string
        |> Decode.andThen
            (\w ->
                case w |> String.toLower of
                    "http" ->
                        Decode.succeed Http

                    "https" ->
                        Decode.succeed Https

                    _ ->
                        Decode.fail ("Unsupported scheme: " ++ w)
            )
