module Serverless.PipelineTests exposing (all)

import Expect exposing (..)
import Serverless.Conn as Conn exposing (..)
import Serverless.Conn.Fuzz as Fuzz exposing (testConnWith, testConn)
import Serverless.Conn.Types exposing (..)
import Serverless.Pipeline as Pipeline exposing (PlugMsg(..))
import Serverless.TestHelpers exposing (..)
import Serverless.TestTypes exposing (..)
import Test exposing (..)


testApplyPipeline : String -> Plug -> (Conn -> Bool -> Expectation) -> Test
testApplyPipeline label pl tester =
    testConn label <|
        \conn ->
            case
                (conn
                    |> body (TextBody "")
                    |> Pipeline.apply
                        (Pipeline.newOptions NoOp responsePort pl)
                        (PlugMsg Pipeline.firstIndexPath NoOp)
                )
            of
                ( newConn, cmd ) ->
                    tester newConn (cmd /= Cmd.none)


all : Test
all =
    describe "Private"
        [ describe "applyPipeline"
            [ testApplyPipeline
                "applies plugs in the correct order"
                (pipeline
                    |> plug (appendToBody "1")
                    |> plug (appendToBody "2")
                    |> plug (appendToBody "3")
                )
              <|
                \conn _ ->
                    conn
                        |> unsentOrCrash
                        |> .body
                        |> Expect.equal (TextBody "123")
            , testApplyPipeline
                "flattens nested pipelines in the correct order"
                (pipeline
                    |> plug (appendToBody "1")
                    |> nest
                        (pipeline
                            |> plug (appendToBody "2")
                            |> plug (appendToBody "3")
                            |> nest
                                (pipeline
                                    |> plug (appendToBody "4")
                                    |> plug (appendToBody "5")
                                )
                            |> plug (appendToBody "6")
                        )
                    |> plug (appendToBody "7")
                )
              <|
                \conn _ ->
                    conn
                        |> unsentOrCrash
                        |> .body
                        |> Expect.equal (TextBody "1234567")
            , testApplyPipeline
                "fork chooses the correct pipeline"
                (pipeline
                    |> plug (appendToBody "1")
                    |> fork (simpleFork "2")
                )
              <|
                \conn _ ->
                    conn
                        |> unsentOrCrash
                        |> .body
                        |> Expect.equal
                            ("1"
                                ++ (conn.req.method |> toString)
                                ++ "2"
                                |> TextBody
                            )
            , testApplyPipeline
                "fork can be followed by a plug which merges from all paths taken"
                (pipeline
                    |> plug (appendToBody "1")
                    |> fork (simpleFork "2")
                    |> plug (appendToBody "3")
                )
              <|
                \conn _ ->
                    conn
                        |> unsentOrCrash
                        |> .body
                        |> Expect.equal
                            ("1"
                                ++ (conn.req.method |> toString)
                                ++ "23"
                                |> TextBody
                            )
            ]
        ]
