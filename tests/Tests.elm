module Tests exposing (..)

import ConnTests
import Test exposing (..)


all : Test
all =
    describe "Serverless"
        [ ConnTests.all
        ]
