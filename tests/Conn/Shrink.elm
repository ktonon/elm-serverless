module Conn.Shrink exposing (..)

import Lazy.List exposing (LazyList, (:::), (+++), empty)
import Serverless.Conn.Types exposing (..)
import Shrink exposing (..)


method : Shrinker Method
method m =
    case m of
        GET ->
            POST ::: PUT ::: DELETE ::: OPTIONS ::: empty

        POST ->
            PUT ::: DELETE ::: OPTIONS ::: empty

        PUT ->
            DELETE ::: OPTIONS ::: empty

        DELETE ->
            OPTIONS ::: empty

        OPTIONS ->
            empty
