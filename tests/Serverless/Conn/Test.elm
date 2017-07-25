module Serverless.Conn.Test exposing (conn, connWith, request)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Serverless.Conn.Fuzz as Fuzz
import Serverless.Conn.Request exposing (Request)
import Test exposing (Test)
import TestHelpers exposing (Conn)


conn : String -> (Conn -> Expectation) -> Test
conn label =
    Test.fuzz Fuzz.conn label


connWith : Fuzzer a -> String -> (( Conn, a ) -> Expectation) -> Test
connWith otherFuzzer label =
    Test.fuzz (Fuzz.tuple ( Fuzz.conn, otherFuzzer )) label


request : String -> (Request -> Expectation) -> Test
request label =
    Test.fuzz Fuzz.request label
