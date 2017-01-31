module ConnTests exposing (all)

import Array
import ConnFuzz as Fuzz exposing (testConn, testConnWith)
import ElmTestBDDStyle exposing (..)
import Expect exposing (..)
import Expect.Extra exposing (contain)
import Serverless.Conn exposing (..)
import Serverless.Types exposing (PipelineState(..), Plug(..), Sendable(..))
import Test exposing (..)
import TestHelpers exposing (..)
import TestTypes exposing (..)


all : Test
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


sf : Conn -> Pipeline
sf =
    simpleFork ""


buildingPipelinesTests : Test
buildingPipelinesTests =
    describe "Building Pipelines"
        [ describe "pipeline"
            [ it "begins a pipeline" <|
                expect (pipeline |> Array.length) to equal 0
            ]
        , describe "toPipeline"
            [ it "makes a pipeline of length 1" <|
                expect (simpleLoop "" NoOp |> toPipeline |> Array.length) to equal 1
            ]
        , describe "plug"
            [ it "extends the pipeline by 1" <|
                expect (pipeline |> plug sp |> Array.length) to equal 1
            , it "wraps a simple conn transformation as a Plug" <|
                expect (pipeline |> plug sp |> Array.get 0)
                    to
                    equal
                    (Just (Plug sp))
            ]
        , describe "loop"
            [ it "extends the pipeline by 1" <|
                expect (pipeline |> loop sl |> Array.length) to equal 1
            , it "wraps an update function as a Plug" <|
                expect (pipeline |> loop sl |> Array.get 0)
                    to
                    equal
                    (Just (Loop sl))
            ]
        , describe "nest"
            [ it "extends the pipeline by the length of the nested pipeline" <|
                expect
                    (pipeline
                        |> plug sp
                        |> loop sl
                        |> nest
                            (pipeline
                                |> plug sp
                                |> plug sp
                                |> loop sl
                            )
                        |> Array.length
                    )
                    to
                    equal
                    5
            ]
        , describe "fork"
            [ it "extends the pipeline by 1" <|
                expect (pipeline |> fork sf |> Array.length) to equal 1
            , it "wraps a router function as a Router" <|
                expect (pipeline |> fork sf |> Array.get 0)
                    to
                    equal
                    (Just (Router sf))
            ]
        ]



-- ROUTING TESTS


routingTests : Test
routingTests =
    describe "Routing"
        [ describe "parseRoute"
            [ testConn "parses the request path" <|
                \conn ->
                    expect
                        (conn
                            |> updateReq (\req -> { req | path = "/foody/bar" })
                            |> parseRoute route NoCanFind
                        )
                        to
                        equal
                        (Foody "bar")
            , testConn "uses the provided default if it fails to parse" <|
                \conn ->
                    expect
                        (conn
                            |> updateReq (\req -> { req | path = "/foozy/bar" })
                            |> parseRoute route NoCanFind
                        )
                        to
                        equal
                        NoCanFind
            ]
        ]



-- RESPONSE TESTS


responseTests : Test
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
                    expect newConn.resp to equal Sent
        , testConn "send issues a side effect" <|
            \conn ->
                let
                    ( _, cmd ) =
                        conn |> send responsePort
                in
                    expect cmd to notEqual Cmd.none
        , testConn "send fails if the conn is already halted" <|
            \conn ->
                let
                    ( _, cmd ) =
                        { conn | resp = Sent } |> send responsePort
                in
                    expect cmd to equal Cmd.none
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


pipelineProcessingTests : Test
pipelineProcessingTests =
    describe "Pipeline Processing"
        [ describe "pipelinePause"
            [ testConn "it sets pipelineState to Paused" <|
                \conn ->
                    case pipelinePause 3 (Cmd.none) responsePort conn of
                        ( newConn, _ ) ->
                            expect newConn.pipelineState to equal (Paused 3)
            , testConn "it increments paused by the correct amount" <|
                \conn ->
                    case
                        { conn | pipelineState = Paused 2 }
                            |> pipelinePause 3 (Cmd.none) responsePort
                    of
                        ( newConn, _ ) ->
                            expect newConn.pipelineState to equal (Paused 5)
            , testConn "it fails if the increment is negative" <|
                \conn ->
                    case pipelinePause -1 (Cmd.none) responsePort conn of
                        ( newConn, _ ) ->
                            expect newConn.pipelineState to equal (Processing)
            , testConn "it sends a failure response if the increment is negative" <|
                \conn ->
                    case pipelinePause -1 (Cmd.none) responsePort conn of
                        ( _, cmd ) ->
                            expect cmd to notEqual (Cmd.none)
            , testConn "it does nothing if the pause increment is zero" <|
                \conn ->
                    case pipelinePause 0 (Cmd.none) responsePort conn of
                        ( newConn, _ ) ->
                            expect newConn.pipelineState to equal (Processing)
            , testConn "it does not send a failure response if the increment is zero" <|
                \conn ->
                    case pipelinePause 0 (Cmd.none) responsePort conn of
                        ( _, cmd ) ->
                            expect cmd to equal (Cmd.none)
            ]
        , describe "pipelineResume"
            [ testConn "it sets pipelineState to Processing if the increment is equal to the current pause count" <|
                \conn ->
                    case
                        { conn | pipelineState = Paused 2 }
                            |> pipelineResume 2 responsePort
                    of
                        ( newConn, _ ) ->
                            expect newConn.pipelineState to equal (Processing)
            , testConn "it decrements paused by the correct amount" <|
                \conn ->
                    case
                        { conn | pipelineState = Paused 5 }
                            |> pipelineResume 4 responsePort
                    of
                        ( newConn, _ ) ->
                            expect newConn.pipelineState to equal (Paused 1)
            , testConn "it fails if the increment is negative" <|
                \conn ->
                    case
                        { conn | pipelineState = Paused 2 }
                            |> pipelineResume -1 responsePort
                    of
                        ( newConn, _ ) ->
                            expect newConn.pipelineState to equal (Paused 2)
            , testConn "it sends a failure response if the increment is negative" <|
                \conn ->
                    case pipelineResume -1 responsePort conn of
                        ( _, cmd ) ->
                            expect cmd to notEqual (Cmd.none)
            , testConn "it does nothing if the resume increment is zero" <|
                \conn ->
                    case pipelineResume 0 responsePort conn of
                        ( newConn, _ ) ->
                            expect newConn.pipelineState to equal (Processing)
            , testConn "it does not send a failure response if the increment is zero" <|
                \conn ->
                    case pipelineResume 0 responsePort conn of
                        ( _, cmd ) ->
                            expect cmd to equal (Cmd.none)
            ]
        ]
