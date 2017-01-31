module PipelineTests exposing (all)

import ConnFuzz as Fuzz exposing (testConnWith, testConn)
import Expect exposing (..)
import Serverless.Conn as Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Pipeline exposing (..)
import Test exposing (..)
import TestHelpers exposing (..)
import TestTypes exposing (..)


testApplyPipeline : String -> Pipeline -> (Conn -> Bool -> Expectation) -> Test
testApplyPipeline label pl tester =
    testConn label <|
        \conn ->
            case
                (conn
                    |> body (TextBody "")
                    |> applyPipeline (Options NoOp responsePort pl) (PlugMsg firstIndexPath NoOp) 0 []
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
