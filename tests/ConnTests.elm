port module ConnTests exposing (all)

import Conn.Fuzz as Fuzz exposing (testConn, testConnWith)
import Conn.PrivateTests
import ElmTestBDDStyle exposing (..)
import Expect exposing (..)
import Expect.Extra exposing (contain)
import Json.Encode as J
import Serverless.Conn exposing (..)
import Serverless.Conn.Private exposing (initResponse)
import Serverless.Conn.Types exposing (..)
import Test exposing (..)


all : Test
all =
    describe "Conn"
        [ Conn.PrivateTests.all
        , responseTest initResponse
        ]


port fakeResponsePort : J.Value -> Cmd msg


responseTest : Response -> Test
responseTest resp =
    describe "Serverless.Conn"
        [ testConnWith Fuzz.body "body sets the response body" <|
            \( conn, val ) ->
                expect (conn |> body val).resp.body to equal val
        , testConnWith Fuzz.status "status sets the response status" <|
            \( conn, val ) ->
                expect (conn |> status val).resp.status to equal val
        , testConn "send does not alter the connection" <|
            \conn ->
                let
                    ( newConn, _ ) =
                        conn |> send fakeResponsePort
                in
                    expect newConn to equal conn
        , testConnWith Fuzz.header "headers adds a response header" <|
            \( conn, val ) ->
                let
                    newConn =
                        conn |> header val
                in
                    expect newConn.resp.headers to contain val
        , testConnWith Fuzz.header "increases the response headers by 1" <|
            \( conn, val ) ->
                let
                    newConn =
                        conn |> header val

                    oldLength =
                        conn.resp.headers |> List.length
                in
                    expect (newConn.resp.headers |> List.length) to equal (oldLength + 1)
        ]
