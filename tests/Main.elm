port module Main exposing (..)

import ConnTests
import Json.Encode exposing (Value)
import PipelineTests
import PoolTests
import Test exposing (..)
import Test.Runner.Node exposing (run, TestProgram)


main : TestProgram
main =
    run emit
        (describe "Serverless"
            [ ConnTests.all
            , PoolTests.all
            , PipelineTests.all
            ]
        )


port emit : ( String, Value ) -> Cmd msg
