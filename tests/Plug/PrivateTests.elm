module Plug.PrivateTests exposing (all)

import Array
import Conn.Fuzz as Fuzz exposing (testConnWith, testConn)
import Conn.TestHelpers exposing (..)
import ElmTestBDDStyle exposing (..)
import Expect exposing (..)
import Serverless.Conn as Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Plug exposing (..)
import Serverless.Plug.Private exposing (..)
import Test exposing (..)
import Tuple


type Msg
    = NoOp


all : Test
all =
    describe "Private"
        [ describe "bakePipeline"
            [ it "converts the list into an array" <|
                expect ([] |> bakePipeline) to equal Array.empty
            , testConn "reverses the order of elements" <|
                \conn ->
                    let
                        raw =
                            pipeline
                                |> plug (appendToBody "1")
                                |> plug (appendToBody "2")
                                |> plug (appendToBody "3")
                    in
                        conn
                            |> body (TextBody "")
                            |> applyPipeline NoOp (bakePipeline raw) (PlugMsg 0 NoOp)
                            |> Tuple.first
                            |> unsentOrCrash
                            |> .body
                            |> Expect.equal (TextBody "123")
            , testConn "flattens nested pipelines in the correct order" <|
                \conn ->
                    let
                        raw =
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
                            |> applyPipeline NoOp (bakePipeline raw) (PlugMsg 0 NoOp)
                            |> Tuple.first
                            |> unsentOrCrash
                            |> .body
                            |> Expect.equal (TextBody "1234567")
            ]
        ]


appendToBody : String -> Conn config model -> Conn config model
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
