module Serverless.Plug.Private exposing (..)

import Array exposing (Array)
import Serverless.Conn.Types exposing (..)
import Serverless.Plug exposing (..)


type alias BakedPipeline config model msg =
    Array (Plug config model msg)


bakePipeline : Plug config model msg -> BakedPipeline config model msg
bakePipeline raw =
    Array.empty


applyPipeline :
    BakedPipeline config model msg
    -> msg
    -> Conn config model
    -> ( Conn config model, Cmd msg )
applyPipeline pipeline msg conn =
    ( conn, Cmd.none )
