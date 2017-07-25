module Serverless.ConnTests
    exposing
        ( all
        , buildingPipelinesTests
        , responseTests
        , routingTests
        )

import Expect
import Expect.Extra as Expect exposing (stringPattern)
import Serverless.Conn as Conn
    exposing
        ( isActive
        , parseRoute
        , pause
        , resume
        , send
        , updateResponse
        )
import Serverless.Conn.Body exposing (text)
import Serverless.Conn.Fuzz as Fuzz
import Serverless.Conn.Response as Response exposing (addHeader, setBody, setStatus)
import Serverless.Conn.Test as Test
import Serverless.Plug as Plug
import TestHelpers exposing (..)
import Test exposing (describe, test)


all : Test.Test
all =
    describe "Serverless.Conn"
        [ buildingPipelinesTests
        , routingTests
        , responseTests
        ]



-- BUILDING PIPELINES TESTS


sp : Conn -> Conn
sp =
    simplePlug ""


sl : Msg -> Conn -> ( Conn, Cmd Msg )
sl =
    simpleLoop ""


sf : Conn -> Plug
sf =
    simpleFork ""


buildingPipelinesTests : Test.Test
buildingPipelinesTests =
    describe "Building Pipelines"
        [ describe "pipeline"
            [ test "begins a pipeline" <|
                \_ ->
                    Expect.equal 0 (Plug.size Plug.pipeline)
            ]
        , describe "plug"
            [ test "extends the pipeline by 1" <|
                \_ ->
                    Expect.equal 1 (Plug.pipeline |> Plug.plug sp |> Plug.size)
            ]
        , describe "loop"
            [ test "extends the pipeline by 1" <|
                \_ ->
                    Expect.equal 1 (Plug.pipeline |> Plug.loop sl |> Plug.size)
            ]
        , describe "nest"
            [ test "extends the pipeline by the length of the nested pipeline" <|
                \_ ->
                    Expect.equal
                        5
                        (Plug.pipeline
                            |> Plug.plug sp
                            |> Plug.loop sl
                            |> Plug.nest
                                (Plug.pipeline
                                    |> Plug.plug sp
                                    |> Plug.plug sp
                                    |> Plug.loop sl
                                )
                            |> Plug.size
                        )
            ]
        , describe "fork"
            [ test "extends the pipeline by 1" <|
                \_ ->
                    Expect.equal 1 (Plug.pipeline |> Plug.fork sf |> Plug.size)
            ]
        ]



-- ROUTING TESTS


routingTests : Test.Test
routingTests =
    describe "Routing"
        [ describe "parseRoute"
            [ Test.conn "parses the request path" <|
                \conn ->
                    Expect.equal
                        (Foody "bar")
                        (parseRoute route NoCanFind "/foody/bar")
            , Test.conn "uses the provided default if it fails to parse" <|
                \conn ->
                    Expect.equal
                        NoCanFind
                        (parseRoute route NoCanFind "/foozy/bar")
            ]
        ]



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
