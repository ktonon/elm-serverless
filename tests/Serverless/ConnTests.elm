module Serverless.ConnTests
    exposing
        ( all
        , responseTests
        )

import Expect
import Expect.Extra as Expect exposing (stringPattern)
import Serverless.Conn as Conn
    exposing
        ( isActive
        , pause
        , resume
        , send
        , updateResponse
        )
import Serverless.Conn.Body exposing (text)
import Serverless.Conn.Fuzz as Fuzz
import Serverless.Conn.Response as Response exposing (addHeader, setBody, setStatus)
import Serverless.Conn.Test as Test
import Test exposing (describe, test)
import TestHelpers exposing (..)


all : Test.Test
all =
    describe "Serverless.Conn"
        [ responseTests
        ]



-- BUILDING PIPELINES TESTS


sp : Conn -> Conn
sp =
    simplePlug ""


sl : Msg -> Conn -> ( Conn, Cmd Msg )
sl =
    simpleLoop ""



-- RESPONSE TESTS


responseTests : Test.Test
responseTests =
    describe "Responding "
        [ Test.conn "body sets the response body" <|
            \conn ->
                conn
                    |> updateResponse (setBody <| text "hello")
                    |> Conn.jsonEncodedResponse
                    |> Expect.match (stringPattern "\"body\":\"hello\"")
        , Test.conn "status sets the response status" <|
            \conn ->
                conn
                    |> updateResponse (setStatus 200)
                    |> Conn.jsonEncodedResponse
                    |> Expect.match (stringPattern "\"statusCode\":200")
        , Test.conn "send sets the response to Sent" <|
            \conn ->
                let
                    ( newConn, _ ) =
                        conn |> send responsePort
                in
                Expect.true "response was not sent" (Conn.isSent newConn)
        , Test.conn "send issues a side effect" <|
            \conn ->
                let
                    ( _, cmd ) =
                        conn |> send responsePort
                in
                Expect.notEqual Cmd.none cmd
        , Test.conn "send fails if the conn is already halted" <|
            \conn ->
                let
                    ( newConn, _ ) =
                        conn |> send responsePort

                    ( _, cmd ) =
                        newConn |> send responsePort
                in
                Expect.equal Cmd.none cmd
        , Test.connWith Fuzz.header "headers adds a response header" <|
            \( conn, ( key, value ) ) ->
                conn
                    |> updateResponse (addHeader ( key, value ))
                    |> Conn.jsonEncodedResponse
                    |> Expect.match (stringPattern ("\"" ++ key ++ "\":\"" ++ value ++ "\""))
        ]
