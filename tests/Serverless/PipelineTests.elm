module Serverless.PipelineTests exposing (all)

import Expect exposing (..)
import Expect.Extra as Expect exposing (stringPattern)
import Serverless.Conn as Conn exposing (updateResponse)
import Serverless.Conn.Body as Body exposing (text)
import Serverless.Conn.Request as Request
import Serverless.Conn.Response as Response exposing (setBody)
import Serverless.Conn.Test as Test
import Serverless.Plug as Plug
import Serverless.Pipeline as Pipeline exposing (PlugMsg(..))
import TestHelpers exposing (..)
import Test exposing (..)


testApplyPipeline : String -> Plug -> (Conn -> Expectation) -> Test
testApplyPipeline label pl tester =
    Test.conn label <|
        \conn ->
            case
                (conn
                    |> updateResponse (setBody <| text "")
                    |> Pipeline.apply
                        (Pipeline.newOptions NoOp pl)
                        (PlugMsg Pipeline.firstIndexPath NoOp)
                )
            of
                ( newConn, cmd ) ->
                    tester newConn


all : Test
all =
    describe "Private"
        [ describe "applyPipeline"
            [ testApplyPipeline
                "applies plugs in the correct order"
                (Plug.pipeline
                    |> Plug.plug (appendToBody "1")
                    |> Plug.plug (appendToBody "2")
                    |> Plug.plug (appendToBody "3")
                )
              <|
                \conn ->
                    conn
                        |> Conn.jsonEncodedResponse
                        |> Expect.match (bodyPattern "123")
            , testApplyPipeline
                "flattens nested pipelines in the correct order"
                (Plug.pipeline
                    |> Plug.plug (appendToBody "1")
                    |> Plug.nest
                        (Plug.pipeline
                            |> Plug.plug (appendToBody "2")
                            |> Plug.plug (appendToBody "3")
                            |> Plug.nest
                                (Plug.pipeline
                                    |> Plug.plug (appendToBody "4")
                                    |> Plug.plug (appendToBody "5")
                                )
                            |> Plug.plug (appendToBody "6")
                        )
                    |> Plug.plug (appendToBody "7")
                )
              <|
                \conn ->
                    conn
                        |> Conn.jsonEncodedResponse
                        |> Expect.match (bodyPattern "1234567")
            , testApplyPipeline
                "fork chooses the correct pipeline"
                (Plug.pipeline
                    |> Plug.plug (appendToBody "1")
                    |> Plug.fork (simpleFork "2")
                )
              <|
                \conn ->
                    conn
                        |> Conn.jsonEncodedResponse
                        |> Expect.match
                            (bodyPattern
                                ("1"
                                    ++ (method conn)
                                    ++ "2"
                                )
                            )
            , testApplyPipeline
                "fork can be followed by a plug which merges from all paths taken"
                (Plug.pipeline
                    |> Plug.plug (appendToBody "1")
                    |> Plug.fork (simpleFork "2")
                    |> Plug.plug (appendToBody "3")
                )
              <|
                \conn ->
                    conn
                        |> Conn.jsonEncodedResponse
                        |> Expect.match
                            (bodyPattern
                                ("1"
                                    ++ (method conn)
                                    ++ "23"
                                )
                            )
            ]
        ]


bodyPattern : String -> Expect.MatchPattern
bodyPattern body =
    stringPattern <| "\"body\":\"" ++ body ++ "\""


method : Conn -> String
method =
    Conn.request
        >> Request.method
        >> toString
