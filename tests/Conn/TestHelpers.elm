module Conn.TestHelpers exposing (..)

import Custom
import Expect exposing (Expectation)
import Serverless.Conn.Private exposing (initResponse)
import Serverless.Conn.Types exposing (..)
import Test exposing (Test, test)


expectUnsent : (Response -> Expectation) -> Custom.Conn -> Expectation
expectUnsent e conn =
    case conn.resp of
        Unsent resp ->
            e resp

        Sent ->
            Expect.fail "expected sendable to be Unsent, but it was Sent"


initResponseTest : String -> (Response -> Expectation) -> Test
initResponseTest label e =
    test label <|
        \_ ->
            case initResponse of
                Unsent resp ->
                    e resp

                Sent ->
                    Expect.fail "initResponse was already Sent"
