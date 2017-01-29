module ConnTests exposing (all)

import Array
import ConnFuzz as Fuzz exposing (testConn, testConnWith)
import Custom
import ElmTestBDDStyle exposing (..)
import Expect exposing (..)
import Expect.Extra exposing (contain)
import Serverless.Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Types exposing (Plug(..), Sendable(..))
import Test exposing (..)
import TestHelpers exposing (..)


all : Test
all =
    describe "Serverless.Conn"
        [ buildingPipelinesTests
        , routingTests
        , responseTests
        , pipelineProcessingTests
        ]


buildingPipelinesTests : Test
buildingPipelinesTests =
    describe "Building Pipelines"
        [ describe "pipeline"
            [ it "begins a pipeline" <|
                expect (pipeline |> Array.length) to equal 0
            ]
        , describe "plug"
            [ it "extends the pipeline by 1" <|
                expect (pipeline |> plug simple |> Array.length) to equal 1
            , it "wraps a simple conn transformation as a Plug" <|
                let
                    result =
                        pipeline |> plug simple |> Array.get 0
                in
                    case result of
                        Just wrapped ->
                            case wrapped of
                                Plug func ->
                                    Expect.pass

                                -- TODO: expect func to notEqual simple
                                _ ->
                                    Expect.fail "expected Plug but got Loop or Pipeline"

                        Nothing ->
                            Expect.fail "pipeline was empty"
            ]
        ]


simple : Custom.Conn -> Custom.Conn
simple =
    body (TextBody "simple")


routingTests : Test
routingTests =
    describe "Routing" []


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
                        conn |> send fakeResponsePort
                in
                    expect newConn.resp to equal Sent
        , testConn "send issues a side effect" <|
            \conn ->
                let
                    ( _, cmd ) =
                        conn |> send fakeResponsePort
                in
                    expect cmd to notEqual Cmd.none
        , testConn "send fails if the conn is already halted" <|
            \conn ->
                let
                    ( _, cmd ) =
                        { conn | resp = Sent } |> send fakeResponsePort
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


pipelineProcessingTests : Test
pipelineProcessingTests =
    describe "Pipeline Processing" []
