module ConnTests exposing (all)

import Conn.Fuzz as Fuzz
import ElmTestBDDStyle exposing (..)
import Expect exposing (..)
import Serverless.Conn exposing (..)
import Serverless.Conn.Private exposing (initResponse)
import Serverless.Conn.Types exposing (..)
import Conn.PrivateTests
import Test exposing (..)


all : Test
all =
    describe "Conn"
        [ Conn.PrivateTests.all
        , responseTest initResponse
        ]


responseTest : Response -> Test
responseTest resp =
    describe "body"
        [ fuzz Fuzz.conn "sets the body" <|
            \conn ->
                expect
                    (conn |> body (TextBody "granny smithers")).resp.body
                    to
                    equal
                    (TextBody "granny smithers")
        ]
