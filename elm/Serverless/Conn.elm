module Serverless.Conn exposing (..)

{-| An HTTP connection with a request and response

@docs Conn, statusCode, body, send
-}

import Json.Encode as J
import Serverless.Conn.PrivateResponse exposing (..)
import Serverless.Conn.Request as Request exposing (..)
import Serverless.Conn.Response as Response exposing (..)


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


{-| Sends a connection response through the given port
-}
send : (J.Value -> Cmd msg) -> Conn config model -> ( Conn config model, Cmd msg )
send port_ conn =
    ( conn
    , conn.resp |> encodeResponse conn.req.id |> port_
    )


{-| Set the response HTTP status code
-}
statusCode : StatusCode -> Conn config model -> Conn config model
statusCode val conn =
    { conn | resp = conn.resp |> (\r -> { r | statusCode = val }) }


{-| Set the response body
-}
body : Body -> Conn config model -> Conn config model
body val conn =
    { conn | resp = conn.resp |> (\r -> { r | body = val }) }
