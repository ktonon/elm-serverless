module Serverless.Conn.Response exposing (..)

{-| Types to help send an HTTP response.

@docs Body, Response, StatusCode
-}


{-| HTTP status code
-}
type StatusCode
    = InvalidStatusCode
    | NumericStatusCode Int
    | Ok_200
    | NotFound_404


{-| Response body
-}
type Body
    = TextBody String


{-| HTTP Response
-}
type alias Response =
    { statusCode : StatusCode
    , body : Body
    }
