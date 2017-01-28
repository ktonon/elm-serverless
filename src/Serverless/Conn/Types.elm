module Serverless.Conn.Types exposing (..)

{-| Types defining a serverless connection

## Connection

@docs Conn, Id, Body, PipelineState

## Request

@docs Request, Method, Scheme, Secure, IpAddress

## Response

@docs Sendable, Response, Status, Charset
-}


{-| A connection with a request and response.

Connections are parameterized with config and model record types which are
specific to the application. Config is loaded once on app startup, while model
is set to a provided initial value for each incomming request.
-}
type alias Conn config model route =
    { pipelineState : PipelineState
    , config : config
    , req : Request
    , resp : Sendable Response
    , model : model
    , route : Maybe route
    }


{-| State of the pipeline for this connection.
-}
type PipelineState
    = Processing
    | Paused Int


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


{-| A sendable type cannot be accessed after it is sent
-}
type Sendable a
    = Unsent a
    | Sent


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
type Status
    = InvalidStatus
    | Code Int


{-| Only Utf8 is supported at this time
-}
type Charset
    = Utf8
