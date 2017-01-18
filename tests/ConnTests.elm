module ConnTests exposing (all)

import Conn.PrivateTests
import Test exposing (..)


all : Test
all =
    describe "Conn"
        [ Conn.PrivateTests.all
        ]
