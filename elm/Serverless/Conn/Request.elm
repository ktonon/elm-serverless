module Serverless.Conn.Request exposing (..)

{-| Defines an HTTP request.

@docs Request, Id, IpAddress, Header, Method, QueryParam, Scheme, Secure
-}


{-| HTTP Request
-}
type alias Request =
    { id : Id
    , host : String
    , method : Method
    , path : String
    , port_ : Int
    , remoteIp : IpAddress
    , headers : List Header
    , scheme : Scheme
    , stage : String
    , queryParams : List QueryParam
    }


{-| Uniquely identifies a request
-}
type alias Id =
    String


{-| Four part IP address
-}
type IpAddress
    = Ip4 ( Int, Int, Int, Int )


{-| Request header with key and value
-}
type alias Header =
    ( String, String )


{-| Query string parameter with a key and value
-}
type alias QueryParam =
    ( String, String )


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
