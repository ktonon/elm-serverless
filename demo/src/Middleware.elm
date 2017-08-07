module Middleware exposing (auth, cors)

{-| Middleware is just a simple function which transforms a connection.
-}

import Serverless.Conn as Conn exposing (request, updateResponse)
import Serverless.Conn.Body exposing (text)
import Serverless.Conn.Response exposing (addHeader)
import Types exposing (Conn)


{-| Simple function to add some cors response headers
-}
cors : Conn -> Conn
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
            Conn.respond ( 401, text "Authorization header not provided" ) conn

        _ ->
            conn
