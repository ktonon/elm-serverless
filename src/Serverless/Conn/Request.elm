module Serverless.Conn.Request exposing
    ( Request, Method(..), Scheme(..)
    , method, path, queryString
    , body, asText, asJson
    , header, query, endpoint, stage
    , init, decoder, methodDecoder, schemeDecoder
    )

{-| Query attributes of the HTTP request.


## Table of Contents

  - [Request Types](#request-types)
  - [Routing](#routing)
  - [Body](#body)
  - [Other Attributes](#other-attributes)


## Request Types

@docs Request, Method, Scheme


## Routing

These attributes are typically involved in routing requests. See the
[Routing Demo](https://github.com/ktonon/elm-serverless/blob/master/demo/src/Routing/API.elm)
for an example.

@docs method, path, queryString


## Body

Functions to access the request body and attempt a cast to a content type. See the
[Forms Demo](https://github.com/ktonon/elm-serverless/blob/master/demo/src/Forms/API.elm)
for an example.

@docs body, asText, asJson


## Other Attributes

@docs header, query, endpoint, stage


## Misc

These functions are typically not needed when building an application. They are
used internally by the framework.

@docs init, decoder, methodDecoder, schemeDecoder

-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, andThen)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Json.Encode
import Serverless.Conn.Body as Body exposing (Body)
import Serverless.Conn.IpAddress as IpAddress exposing (IpAddress)
import Serverless.Conn.KeyValueList as KeyValueList


{-| An HTTP request.
-}
type Request
    = Request Model


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
    { body : Body
    , headers : Dict String String
    , host : String
    , method : Method
    , path : String
    , port_ : Int
    , remoteIp : IpAddress
    , scheme : Scheme
    , stage : String
    , queryParams : Dict String String
    , queryString : String
    }



-- CONSTRUCTORS


{-| Initialize an empty Request.

Exposed for unit testing. Incoming connections initialize requests using
JSON decoders.

-}
init : Request
init =
    Request
        (Model
            Body.empty
            Dict.empty
            ""
            GET
            "/"
            80
            IpAddress.loopback
            Http
            "test"
            Dict.empty
            ""
        )



-- GETTERS


{-| Request body.
-}
body : Request -> Body
body (Request request) =
    request.body


{-| Extract the String from the body.
-}
asText : Body -> Result String String
asText =
    Body.asText


{-| Extract the JSON value from the body.
-}
asJson : Body -> Result String Json.Encode.Value
asJson =
    Body.asJson


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


{-| Get a request header by name.

Headers are normalized such that the keys are always `lower-case`.

-}
header : String -> Request -> Maybe String
header key (Request { headers }) =
    Dict.get key headers


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
method (Request request) =
    request.method


{-| Request path.

While you can access this attribute directly, it is better to provide a
`parseRoute` function to the framework.

-}
path : Request -> String
path (Request request) =
    request.path


{-| Get a query argument by name.
-}
query : String -> Request -> Maybe String
query name (Request { queryParams }) =
    Dict.get name queryParams


{-| The original query string.

While you can access this attribute directly, it is better to provide a
`parseRoute` function to the framework.

-}
queryString : Request -> String
queryString (Request request) =
    request.queryString


{-| IP address of the requesting entity.
-}
remoteIp : Request -> IpAddress
remoteIp (Request request) =
    request.remoteIp


{-| Serverless deployment stage.

See <https://serverless.com/framework/docs/providers/aws/guide/deploying/>

-}
stage : Request -> String
stage (Request request) =
    request.stage



-- JSON


{-| JSON decoder for HTTP requests.
-}
decoder : Decoder Request
decoder =
    Decode.succeed HeadersOnly
        |> required "headers" (KeyValueList.decoder |> Decode.map Dict.fromList)
        |> andThen (Decode.map Request << modelDecoder)


type alias HeadersOnly =
    { headers : Dict String String
    }


modelDecoder : HeadersOnly -> Decoder Model
modelDecoder { headers } =
    Decode.succeed Model
        |> required "body" (Body.decoder <| Dict.get "content-type" headers)
        |> hardcoded headers
        |> required "host" Decode.string
        |> required "method" methodDecoder
        |> required "path" Decode.string
        |> required "port" Decode.int
        |> required "remoteIp" IpAddress.decoder
        |> required "scheme" schemeDecoder
        |> required "stage" Decode.string
        |> required "queryParams" (KeyValueList.decoder |> Decode.map Dict.fromList)
        |> required "queryString" Decode.string


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
