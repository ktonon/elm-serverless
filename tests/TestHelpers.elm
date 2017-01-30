module TestHelpers exposing (..)

import TestTypes exposing (..)
import Expect exposing (Expectation)
import Serverless.Pool exposing (initResponse)
import Serverless.Conn.Types exposing (Response, Request)
import Serverless.Types exposing (Sendable(..), ResponsePort)
import Test exposing (Test, test)
import UrlParser exposing (Parser, (</>), map, oneOf, s, string, top)


unsentOrCrash : Conn -> Response
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


updateReq : (Request -> Request) -> Conn -> Conn
updateReq update conn =
    { conn | req = update conn.req }



-- ROUTING


type Route
    = Home
    | Foody String
    | NoCanFind


route : Parser (Route -> a) a
route =
    oneOf
        [ map Home top
        , map Foody (s "foody" </> string)
        ]
