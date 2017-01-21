module Tests exposing (..)

import ConnTests
import PlugTests
import Test exposing (..)


all : Test
all =
    describe "Serverless"
        [ ConnTests.all
        , PlugTests.all
        ]
