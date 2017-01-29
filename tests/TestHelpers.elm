port module TestHelpers exposing (..)

import Custom
import Expect exposing (Expectation)
import Serverless.Pool exposing (initResponse)
import Serverless.Conn.Types exposing (Response)
import Serverless.Types exposing (Sendable(..), ResponsePort)
import Test exposing (Test, test)


port fakeResponsePort : ResponsePort msg


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
