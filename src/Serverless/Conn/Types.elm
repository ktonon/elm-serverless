module Serverless.Conn.Types exposing (..)

{-| Types defining a serverless connection

## General

@docs Id, Body

## Request

@docs Request, Method, Scheme, Secure, IpAddress

## Response

@docs Response, Status, Charset
-}

import Json.Encode


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
    { body : Body
    , charset : Charset
    , headers : List ( String, String )
    , status : Status
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
    | JsonBody Json.Encode.Value


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
type Status
    = InvalidStatus
    | Code Int


{-| Only Utf8 is supported at this time
-}
type Charset
    = Utf8
