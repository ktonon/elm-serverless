module Serverless.ConnTests exposing (..)

import Array
import Expect
import Expect.Extra
import Serverless.Conn exposing (..)
import Serverless.Conn.Fuzz as Fuzz exposing (testConn, testConnWith)
import Serverless.TestTypes exposing (Conn, Msg, responsePort)
import Serverless.TestHelpers exposing (..)
import Serverless.Types exposing (PipelineState(..), Plug(..), Sendable(..))
import Test exposing (describe, test)


all : Test.Test
all =
    describe "Serverless.Conn"
        [ buildingPipelinesTests
        , routingTests
        , responseTests
        , pipelineProcessingTests
        ]



-- BUILDING PIPELINES TESTS


sp : Conn -> Conn
sp =
    simplePlug ""


sl : Msg -> Conn -> ( Conn, Cmd Msg )
sl =
    simpleLoop ""


sf : Conn -> Serverless.TestTypes.Plug
sf =
    simpleFork ""


buildingPipelinesTests : Test.Test
buildingPipelinesTests =
    describe "Building Pipelines"
        [ describe "pipeline"
            [ test "begins a pipeline" <|
                \_ ->
                    Expect.equal 0 (pipelineCount pipeline)
            ]
        , describe "plug"
            [ test "extends the pipeline by 1" <|
                \_ ->
                    Expect.equal 1 (pipeline |> plug sp |> pipelineCount)
            , test "wraps a simple conn transformation as a Plug" <|
                \_ ->
                    Expect.equal
                        (Pipeline (Array.fromList [ Simple sp ]))
                        (pipeline |> plug sp)
            ]
        , describe "loop"
            [ test "extends the pipeline by 1" <|
                \_ ->
                    Expect.equal 1 (pipeline |> loop sl |> pipelineCount)
            , test "wraps an update function as a Plug" <|
                \_ ->
                    Expect.equal
                        (Pipeline (Array.fromList [ Update sl ]))
                        (pipeline |> loop sl)
            ]
        , describe "nest"
            [ test "extends the pipeline by the length of the nested pipeline" <|
                \_ ->
                    Expect.equal
                        5
                        (pipeline
                            |> plug sp
                            |> loop sl
                            |> nest
                                (pipeline
                                    |> plug sp
                                    |> plug sp
                                    |> loop sl
                                )
                            |> pipelineCount
                        )
            ]
        , describe "fork"
            [ test "extends the pipeline by 1" <|
                \_ ->
                    Expect.equal 1 (pipeline |> fork sf |> pipelineCount)
            , test "wraps a router function as a Router" <|
                \_ ->
                    Expect.equal
                        (Pipeline (Array.fromList [ Router sf ]))
                        (pipeline |> fork sf)
            ]
        ]



-- ROUTING TESTS


routingTests : Test.Test
routingTests =
    describe "Routing"
        [ describe "parseRoute"
            [ testConn "parses the request path" <|
                \conn ->
                    Expect.equal
                        (Foody "bar")
                        (conn
                            |> updateReq (\req -> { req | path = "/foody/bar" })
                            |> parseRoute route NoCanFind
                        )
            , testConn "uses the provided default if it fails to parse" <|
                \conn ->
                    Expect.equal
                        NoCanFind
                        (conn
                            |> updateReq (\req -> { req | path = "/foozy/bar" })
                            |> parseRoute route NoCanFind
                        )
            ]
        ]



-- RESPONSE TESTS


responseTests : Test.Test
responseTests =
    describe "Responding "
        [ testConnWith Fuzz.body "body sets the response body" <|
            \( conn, val ) ->
                conn
                    |> body val
                    |> unsentOrCrash
                    |> .body
                    |> Expect.equal val
        , testConnWith Fuzz.status "status sets the response status" <|
            \( conn, val ) ->
                conn
                    |> status val
                    |> unsentOrCrash
                    |> .status
                    |> Expect.equal val
        , testConn "send sets the response to Sent" <|
            \conn ->
                let
                    ( newConn, _ ) =
                        conn |> send responsePort
                in
                    Expect.equal Sent newConn.resp
        , testConn "send issues a side effect" <|
            \conn ->
                let
                    ( _, cmd ) =
                        conn |> send responsePort
                in
                    Expect.notEqual Cmd.none cmd
        , testConn "send fails if the conn is already halted" <|
            \conn ->
                let
                    ( _, cmd ) =
                        { conn | resp = Sent } |> send responsePort
                in
                    Expect.equal Cmd.none cmd
        , testConnWith Fuzz.header "headers adds a response header" <|
            \( conn, val ) ->
                conn
                    |> header val
                    |> unsentOrCrash
                    |> .headers
                    |> Expect.Extra.member val
        , testConnWith Fuzz.header "increases the response headers by 1" <|
            \( conn, val ) ->
                let
                    oldLength =
                        case conn.resp of
                            Unsent resp ->
                                resp.headers |> List.length

                            Sent ->
                                -2
                in
                    conn
                        |> header val
                        |> unsentOrCrash
                        |> .headers
                        |> List.length
                        |> Expect.equal (oldLength + 1)
        ]



-- PIPELINE PROCESSING TESTS


pipelineProcessingTests : Test.Test
pipelineProcessingTests =
    describe "Pipeline Processing"
        [ describe "pipelinePause"
            [ testConn "it sets pipelineState to Paused" <|
                \conn ->
                    case pipelinePause 3 (Cmd.none) responsePort conn of
                        ( newConn, _ ) ->
                            Expect.equal (Paused 3) newConn.pipelineState
            , testConn "it increments paused by the correct amount" <|
                \conn ->
                    case
                        { conn | pipelineState = Paused 2 }
                            |> pipelinePause 3 (Cmd.none) responsePort
                    of
                        ( newConn, _ ) ->
                            Expect.equal (Paused 5) newConn.pipelineState
            , testConn "it fails if the increment is negative" <|
                \conn ->
                    case pipelinePause -1 (Cmd.none) responsePort conn of
                        ( newConn, _ ) ->
                            Expect.equal (Processing) newConn.pipelineState
            , testConn "it sends a failure response if the increment is negative" <|
                \conn ->
                    case pipelinePause -1 (Cmd.none) responsePort conn of
                        ( _, cmd ) ->
                            Expect.notEqual (Cmd.none) cmd
            , testConn "it does nothing if the pause increment is zero" <|
                \conn ->
                    case pipelinePause 0 (Cmd.none) responsePort conn of
                        ( newConn, _ ) ->
                            Expect.equal Processing newConn.pipelineState
            , testConn "it does not send a failure response if the increment is zero" <|
                \conn ->
                    case pipelinePause 0 (Cmd.none) responsePort conn of
                        ( _, cmd ) ->
                            Expect.equal Cmd.none cmd
            ]
        , describe "pipelineResume"
            [ testConn "it sets pipelineState to Processing if the increment is equal to the current pause count" <|
                \conn ->
                    case
                        { conn | pipelineState = Paused 2 }
                            |> pipelineResume 2 responsePort
                    of
                        ( newConn, _ ) ->
                            Expect.equal Processing newConn.pipelineState
            , testConn "it decrements paused by the correct amount" <|
                \conn ->
                    case
                        { conn | pipelineState = Paused 5 }
                            |> pipelineResume 4 responsePort
                    of
                        ( newConn, _ ) ->
                            Expect.equal (Paused 1) newConn.pipelineState
            , testConn "it fails if the increment is negative" <|
                \conn ->
                    case
                        { conn | pipelineState = Paused 2 }
                            |> pipelineResume -1 responsePort
                    of
                        ( newConn, _ ) ->
                            Expect.equal (Paused 2) newConn.pipelineState
            , testConn "it sends a failure response if the increment is negative" <|
                \conn ->
                    case pipelineResume -1 responsePort conn of
                        ( _, cmd ) ->
                            Expect.notEqual Cmd.none cmd
            , testConn "it does nothing if the resume increment is zero" <|
                \conn ->
                    case pipelineResume 0 responsePort conn of
                        ( newConn, _ ) ->
                            Expect.equal Processing newConn.pipelineState
            , testConn "it does not send a failure response if the increment is zero" <|
                \conn ->
                    case pipelineResume 0 responsePort conn of
                        ( _, cmd ) ->
                            Expect.equal Cmd.none cmd
            ]
        ]
