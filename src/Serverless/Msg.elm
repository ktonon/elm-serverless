module Serverless.Msg exposing (..)

import Array exposing (Array)
import Json.Encode as J
import Serverless.Conn.Types exposing (Id)


type Msg msg
    = RawRequest J.Value
    | HandlerMsg Id (PlugMsg msg)


type PlugMsg msg
    = PlugMsg IndexPath msg


type alias IndexPath =
    Array Index


type alias Index =
    Int


type alias IndexDepth =
    Int
