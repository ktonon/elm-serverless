module Quoted.Middleware exposing (auth, cors)

{-| Middleware is just a simple function which transforms a connection.
-}

import Quoted.Types exposing (Conn)
import Serverless.Conn exposing (config, header, request, textBody, toSent, updateResponse)
import Serverless.Conn.Response exposing (addHeader, setBody, setStatus)


{-| Simple function to add some cors response headers
-}
cors :
    Serverless.Conn.Conn config model route
    -> Serverless.Conn.Conn config model route
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
        ( config conn |> .enableAuth
        , header "authorization" conn
        )
    of
        ( True, Nothing ) ->
            conn
                |> updateResponse
                    (setStatus 401
                        >> setBody (textBody "Authorization header not provided")
                    )
                |> toSent

        _ ->
            conn
