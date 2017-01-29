module Middleware.Cors exposing (..)

import Serverless.Conn exposing (..)
import Serverless.Conn.Types exposing (Method)
import Serverless.Types exposing (Conn)


cors : String -> List Method -> Conn config model -> Conn config model
cors origin methods =
    (header ( "access-control-allow-origin", origin ))
        >> (header
                ( "access-control-allow-headers"
                , methods
                    |> List.map toString
                    |> String.join ", "
                )
           )
