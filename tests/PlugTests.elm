module PlugTests exposing (all)

import Custom
import ElmTestBDDStyle exposing (..)
import Expect exposing (..)
import Plug.PrivateTests
import Serverless.Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Plug exposing (..)
import Test exposing (..)


all : Test
all =
    describe "Plug"
        [ Plug.PrivateTests.all
        , describe "pipeline"
            [ it "begins a pipeline" <|
                expect (pipeline |> List.length) to equal 0
            ]
        , describe "plug"
            [ it "extends the pipeline by 1" <|
                expect (pipeline |> plug simple |> List.length) to equal 1
            , it "wraps a simple conn transformation as a Plug" <|
                let
                    result =
                        pipeline |> plug simple |> List.head
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
    body (TextBody "foo")
