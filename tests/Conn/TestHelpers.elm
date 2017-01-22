module Conn.TestHelpers exposing (..)

import Custom
import Expect exposing (Expectation)
import Serverless.Conn.Private exposing (initResponse)
import Serverless.Conn.Types exposing (..)
import Test exposing (Test, test)


unsentOrCrash : Custom.Conn -> Response
unsentOrCrash conn =
    case conn.resp of
        Unsent resp ->
            resp

        Sent ->
            Debug.crash "expected sendable to be Unsent, but it was Sent"


initResponseTest : String -> (Response -> Expectation) -> Test
initResponseTest label e =
    test label <|
        \_ ->
            case initResponse of
                Unsent resp ->
                    e resp

                Sent ->
                    Expect.fail "initResponse was already Sent"
