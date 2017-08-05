module Middleware exposing (cors)

{-| Middleware is just a simple function which transforms a connection.
-}

import Serverless.Conn exposing (updateResponse)
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
