module Serverless.Conn.Types exposing (..)

{-| Types defining a serverless connection

@docs Conn, Request, Response, Id, Body, Method, Scheme, Secure, IpAddress, StatusCode
-}


{-| A connection with a request and response.

Connections are parameterized with config and model record types which are
specific to the application. Config is loaded once on app startup, while model
is set to a provided initial value for each incomming request.
-}
type alias Conn config model =
    { config : config
    , req : Request
    , resp : Response
    , model : model
    }


{-| HTTP Request
-}
type alias Request =
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


{-| HTTP Response
-}
type alias Response =
    { statusCode : StatusCode
    , body : Body
    }


{-| Uniquely identifies a connection
-}
type alias Id =
    String


{-| Request or Response body
-}
type Body
    = NoBody
    | TextBody String


{-| HTTP request message type
-}
type Method
    = GET
    | POST
    | PUT
    | DELETE
    | OPTIONS


{-| Supported connection schemes (protocols)
-}
type Scheme
    = Http Secure


{-| Is this connection over SSL?
-}
type Secure
    = Secure
    | Insecure


{-| Four part IP address
-}
type IpAddress
    = Ip4 ( Int, Int, Int, Int )


{-| HTTP status code
-}
type StatusCode
    = InvalidStatusCode
    | NumericStatusCode Int
    | Ok_200
    | NotFound_404
