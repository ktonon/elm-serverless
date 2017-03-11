module Serverless.Port
    exposing
        ( IO
        , Request
        , Response
        )

{-| Port type definitions.

An elm library cannot expose a module with ports. The following port definitions
are provided so that your program can create the necessary request and response
ports.

@docs IO, Request, Response

-}

import Json.Encode


-- PORTS


{-| Value passed between Elm and JavaScript.
-}
type alias IO =
    ( String, String, Json.Encode.Value )


{-| Type of port through which the request is received.
Set your request port to this type.

    port requestPort : Serverless.Port.Request msg

-}
type alias Request msg =
    (IO -> msg) -> Sub msg


{-| Type of port through which the request is sent.
Set your response port to this type.

    port responsePort : Serverless.Port.Response msg

-}
type alias Response msg =
    IO -> Cmd msg
