module Serverless.ConnTests exposing
    ( all
    , buildingPipelinesTests
    , responseTests
    )

import Expect
import Expect.Extra as Expect exposing (stringPattern)
import Json.Encode
import Serverless.Conn as Conn
    exposing
        ( send
        , toSent
        , unsent
        , updateResponse
        )
import Serverless.Conn.Body exposing (binary, text)
import Serverless.Conn.Fuzz as Fuzz
import Serverless.Conn.Response as Response exposing (addHeader, setBody, setStatus)
import Serverless.Conn.Test as Test
import Serverless.Plug as Plug
import Test exposing (describe, test)
import TestHelpers exposing (..)


all : Test.Test
all =
    describe "Serverless.Conn"
        [ buildingPipelinesTests
        , responseTests
        ]



-- BUILDING PIPELINES TESTS


sp : Conn -> Conn
sp =
    simplePlug ""


sl : Msg -> Conn -> ( Conn, Cmd Msg )
sl =
    simpleLoop ""


buildingPipelinesTests : Test.Test
buildingPipelinesTests =
    describe "Building Pipelines"
        [ describe "pipeline"
            [ test "begins a pipeline" <|
                \_ ->
                    Expect.equal 0 (Plug.size Plug.pipeline)
            ]
        , describe "plug"
            [ test "extends the pipeline by 1" <|
                \_ ->
                    Expect.equal 1 (Plug.pipeline |> Plug.plug sp |> Plug.size)
            ]
        , describe "nest"
            [ test "extends the pipeline by the length of the nested pipeline" <|
                \_ ->
                    Expect.equal
                        5
                        (Plug.pipeline
                            |> Plug.plug sp
                            |> Plug.plug sp
                            |> Plug.nest
                                (Plug.pipeline
                                    |> Plug.plug sp
                                    |> Plug.plug sp
                                    |> Plug.plug sp
                                )
                            |> Plug.size
                        )
            ]
        ]



-- RESPONSE TESTS


responseTests : Test.Test
responseTests =
    describe "Responding "
        [ Test.conn "body sets the response body" <|
            \conn ->
                conn
                    |> updateResponse (setBody <| text "hello")
                    |> Conn.jsonEncodedResponse
                    |> Json.Encode.encode 0
                    |> Expect.match (stringPattern "\"body\":\"hello\"")
        , Test.conn "status sets the response status" <|
            \conn ->
                conn
                    |> updateResponse (setStatus 200)
                    |> Conn.jsonEncodedResponse
                    |> Json.Encode.encode 0
                    |> Expect.match (stringPattern "\"statusCode\":200")
        , Test.conn "send sets the response to Sent" <|
            \conn ->
                Expect.equal Nothing (toSent conn |> unsent)
        , Test.connWith Fuzz.header "headers adds a response header" <|
            \( conn, ( key, value ) ) ->
                conn
                    |> updateResponse (addHeader ( key, value ))
                    |> Conn.jsonEncodedResponse
                    |> Json.Encode.encode 0
                    |> Expect.match (stringPattern ("\"" ++ key ++ "\":\"" ++ value ++ "\""))
        , Test.conn "binary sets the response header" <|
            \conn ->
                conn
                    |> updateResponse (setBody <| binary "application/octet-stream" "hello")
                    |> Conn.jsonEncodedResponse
                    |> Json.Encode.encode 0
                    |> Expect.match (stringPattern "\"content-type\":\"application/octet-stream; charset=utf-8\"")
        , Test.conn "binary sets isBase64Encoded to true" <|
            \conn ->
                conn
                    |> updateResponse (setBody <| binary "application/octet-stream" "hello")
                    |> Conn.jsonEncodedResponse
                    |> Json.Encode.encode 0
                    |> Expect.match (stringPattern "\"isBase64Encoded\":true")
        ]
