module Serverless.PoolTests exposing (..)

import Dict
import Expect
import Expect.Extra
import Logging exposing (nullLogger)
import Serverless.Conn.Fuzz as Fuzz exposing (testConnWith, testReq)
import Serverless.Conn.Types exposing (Body(..), Status(..), Response)
import Serverless.Pool as Pool
import Serverless.TestTypes exposing (Config, Model)
import Serverless.Types exposing (Sendable(..))
import Test exposing (describe, test)


all : Test.Test
all =
    describe "Serverless.Pool"
        [ describe "empty"
            [ test "creates a pool with no connections" <|
                \_ ->
                    Expect.equal
                        0
                        (Pool.empty (Model 1) (Config "secret" |> Just)
                            |> .conn
                            |> Dict.size
                        )
            ]
        , describe "add"
            [ testReq "fails if the pool has no config" <|
                \req ->
                    Expect.equal
                        0
                        (Pool.empty (Model 1) Nothing
                            |> Pool.add nullLogger req
                            |> .conn
                            |> Dict.size
                        )
            ]
        , describe "initResponse"
            [ initResponseTest "is unsent" <|
                \_ ->
                    Expect.pass
            , initResponseTest "has no body" <|
                \resp -> Expect.equal NoBody resp.body
            , initResponseTest "has a default no-cache header" <|
                \resp ->
                    Expect.Extra.member
                        ( "cache-control"
                        , "max-age=0, private, must-revalidate"
                        )
                        resp.headers
            , initResponseTest "has an invalid status code" <|
                \resp -> Expect.equal InvalidStatus resp.status
            ]
        ]


initResponseTest : String -> (Response -> Expect.Expectation) -> Test.Test
initResponseTest label e =
    test label <|
        \_ ->
            case Pool.initResponse of
                Unsent resp ->
                    e resp

                Sent ->
                    Expect.fail "initResponse was already Sent"
