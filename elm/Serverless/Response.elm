module Serverless.Response exposing (..)

{-| Types to help send an HTTP response.

@docs StatusCode, ResponseBody, Port
-}


{-| HTTP status code
-}
type alias StatusCode =
    Int


{-| Response body as a string
-}
type alias ResponseBody =
    String


{-| Defines the type that should be used for an elm port to send the response.
-}
type alias Port msg =
    ( StatusCode, ResponseBody ) -> Cmd msg
