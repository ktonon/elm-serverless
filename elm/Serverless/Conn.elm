module Serverless.Conn exposing (..)

{-| An HTTP connection with a request and response

# Response Mutations
@docs body, statusCode, send
-}

import Json.Encode as J
import Serverless.Conn.Types exposing (..)
import Serverless.Conn.Private exposing (..)


-- REQUEST
-- RESPONSE


{-| Set the response body
-}
body : Body -> Conn config model -> Conn config model
body val conn =
    { conn | resp = conn.resp |> (\r -> { r | body = val }) }


{-| Set the response HTTP status code
-}
statusCode : StatusCode -> Conn config model -> Conn config model
statusCode val conn =
    { conn | resp = conn.resp |> (\r -> { r | statusCode = val }) }


{-| Sends a connection response through the given port
-}
send : (J.Value -> Cmd msg) -> Conn config model -> ( Conn config model, Cmd msg )
send port_ conn =
    ( conn
    , conn.resp |> encodeResponse conn.req.id |> port_
    )
