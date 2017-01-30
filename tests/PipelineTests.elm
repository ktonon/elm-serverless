module PipelineTests exposing (all)

import ConnFuzz as Fuzz exposing (testConnWith, testConn)
import Expect exposing (..)
import Serverless.Conn as Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Pipeline exposing (..)
import Serverless.Types exposing (Sendable(..))
import Test exposing (..)
import TestHelpers exposing (..)
import TestTypes exposing (..)
import Tuple


type Msg
    = NoOp


all : Test
all =
    describe "Private"
        [ describe "applyPipeline"
            [ testConn "flattens nested pipelines in the correct order" <|
                \conn ->
                    let
                        pl =
                            pipeline
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
                    in
                        conn
                            |> body (TextBody "")
                            |> applyPipeline (Options NoOp responsePort pl) (PlugMsg firstIndexPath NoOp) 0 []
                            |> Tuple.first
                            |> unsentOrCrash
                            |> .body
                            |> Expect.equal (TextBody "1234567")
            ]
        ]


appendToBody : String -> Conn -> Conn
appendToBody x conn =
    case conn.resp of
        Unsent resp ->
            case resp.body of
                TextBody y ->
                    conn |> body (TextBody (y ++ x))

                NoBody ->
                    conn |> body (TextBody x)

        Sent ->
            conn
