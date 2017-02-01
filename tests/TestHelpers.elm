module TestHelpers exposing (..)

import Array
import Expect exposing (Expectation)
import Serverless.Conn exposing (body, pipeline, plug)
import Serverless.Conn.Types exposing (Body(..), Method(..), Response, Request)
import Serverless.Pool exposing (initResponse)
import Serverless.Types exposing (Sendable(..), ResponsePort)
import Test exposing (Test, test)
import TestTypes exposing (..)
import UrlParser exposing (Parser, (</>), map, oneOf, s, string, top)


appendToBody : String -> Conn -> Conn
appendToBody x conn =
    case conn.resp of
        Unsent resp ->
            case resp.body of
                TextBody y ->
                    conn |> body (TextBody (y ++ x))

                JsonBody _ ->
                    Debug.crash "appendToBody only works with TextBody"

                NoBody ->
                    conn |> body (TextBody x)

        Sent ->
            conn


initResponseTest : String -> (Response -> Expectation) -> Test
initResponseTest label e =
    test label <|
        \_ ->
            case initResponse of
                Unsent resp ->
                    e resp

                Sent ->
                    Expect.fail "initResponse was already Sent"


unsentOrCrash : Conn -> Response
unsentOrCrash conn =
    case conn.resp of
        Unsent resp ->
            resp

        Sent ->
            Debug.crash "expected sendable to be Unsent, but it was Sent"


{-| The number of plugs in the pipeline.
-}
pipelineCount : Plug -> Int
pipelineCount plug =
    case plug of
        Serverless.Types.Pipeline pipeline ->
            pipeline |> Array.length

        _ ->
            1


updateReq : (Request -> Request) -> Conn -> Conn
updateReq update conn =
    { conn | req = update conn.req }


simplePlug : String -> Conn -> Conn
simplePlug =
    appendToBody


simpleLoop : String -> Msg -> Conn -> ( Conn, Cmd Msg )
simpleLoop label msg conn =
    ( conn |> appendToBody label, Cmd.none )


simpleFork : String -> Conn -> Plug
simpleFork label conn =
    case conn.req.method of
        GET ->
            pipeline |> plug (simplePlug ("GET" ++ label))

        POST ->
            pipeline |> plug (simplePlug ("POST" ++ label))

        PUT ->
            pipeline |> plug (simplePlug ("PUT" ++ label))

        DELETE ->
            pipeline |> plug (simplePlug ("DELETE" ++ label))

        OPTIONS ->
            pipeline |> plug (simplePlug ("OPTIONS" ++ label))



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
