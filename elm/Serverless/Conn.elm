module Serverless.Conn exposing (..)

{-| An HTTP connection with a request and response

# Response Mutations
@docs body, header, status, send
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
    case conn.resp of
        Unsent resp ->
            { conn | resp = Unsent { resp | body = val } }

        Sent ->
            conn


{-| Set a response header
-}
header : ( String, String ) -> Conn config model -> Conn config model
header ( key, value ) conn =
    case conn.resp of
        Unsent resp ->
            { conn
                | resp =
                    Unsent
                        { resp
                            | headers =
                                ( key |> String.toLower, value )
                                    :: resp.headers
                        }
            }

        Sent ->
            conn


{-| Set the response HTTP status code
-}
status : Status -> Conn config model -> Conn config model
status val conn =
    case conn.resp of
        Unsent resp ->
            { conn | resp = Unsent { resp | status = val } }

        Sent ->
            conn


{-| Sends a connection response through the given port
-}
send : (J.Value -> Cmd msg) -> Conn config model -> ( Conn config model, Cmd msg )
send port_ conn =
    case conn.resp of
        Unsent resp ->
            ( { conn | resp = Sent }
            , resp |> encodeResponse conn.req.id |> port_
            )

        Sent ->
            ( conn
            , Cmd.none
            )
