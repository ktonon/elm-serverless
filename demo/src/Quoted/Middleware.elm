module Quoted.Middleware exposing (auth, cors)

{-| Middleware is just a simple function which transforms a connection.
-}

import Quoted.Types exposing (Conn)
import Serverless.Conn as Conn exposing (request, updateResponse)
import Serverless.Conn.Body exposing (text)
import Serverless.Conn.Response exposing (addHeader, setBody, setStatus)


{-| Simple function to add some cors response headers
-}
cors : Conn.Conn config model route interop -> Conn.Conn config model route interop
cors conn =
    updateResponse
        (addHeader ( "access-control-allow-origin", "*" )
            >> addHeader ( "access-control-allow-methods", "GET,POST" )
         -- ...
        )
        conn


{-| Dumb auth just checks if auth header is present.

To demonstrate middleware which sends a response.

-}
auth : Conn -> Conn
auth conn =
    case
        ( Conn.config conn |> .enableAuth
        , Conn.header "authorization" conn
        )
    of
        ( True, Nothing ) ->
            conn
                |> updateResponse
                    (setStatus 401
                        >> setBody (text "Authorization header not provided")
                    )
                |> Conn.toSent

        _ ->
            conn
