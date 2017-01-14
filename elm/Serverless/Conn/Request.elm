module Serverless.Conn.Request exposing (..)

{-| Defines an HTTP request.

@docs Id, Method, Request
-}


{-| Uniquely identifies a request
-}
type alias Id =
    String


{-| HTTP request message type
-}
type Method
    = GET
    | POST
    | PUT
    | DELETE
    | OPTIONS


{-| HTTP Request
-}
type alias Request =
    { id : Id
    , method : Method
    , path : String
    , stage : String
    }
