module Serverless.Conn.PoolTests exposing (all)

import Dict
import Expect
import Logging exposing (nullLogger)
import Serverless.Conn.Response as Response exposing (Response, Status)
import Serverless.Conn.Test as Test
import Serverless.Conn.Pool as Pool
import TestHelpers exposing (Config, Model)
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
            [ Test.request "fails if the pool has no config" <|
                \req ->
                    Expect.equal
                        0
                        (Pool.empty (Model 1) Nothing
                            |> Pool.add nullLogger req
                            |> .conn
                            |> Dict.size
                        )
            ]
        ]


initResponseTest : String -> (Response -> Expect.Expectation) -> Test.Test
initResponseTest label e =
    test label <|
        \_ ->
            e Response.init
