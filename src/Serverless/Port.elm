module Serverless.Port exposing (Request, Response)

{-| Port type definitions.

An elm library cannot expose a module with ports. The following port definitions
are provided so that your program can create the necessary request and response
ports.

@docs Request, Response
-}

import Json.Encode


-- PORTS


{-| Type of port through which the request is received.
Set your request port to this type.

    -- Usage
    port requestPort : Serverless.Port.Request msg
-}
type alias Request msg =
    (Json.Encode.Value -> msg) -> Sub msg


{-| Type of port through which the request is sent.
Set your response port to this type.

    -- Usage
    port responsePort : Serverless.Port.Response msg
-}
type alias Response msg =
    Json.Encode.Value -> Cmd msg
