module Serverless.Conn.EncodeTests exposing (..)

import Expect
import Expect.Extra
import Json.Encode as J
import Serverless.Conn as Conn
import Serverless.Conn.Encode as Encode
import Serverless.Conn.Fuzz as Fuzz exposing (testConnWith)
import Serverless.Conn.Types exposing (Body(..))
import Test exposing (describe, test)


all : Test.Test
all =
    describe "Serverless.Conn.Encode"
        [ describe "encodeBody"
            [ test "encodes NoBody as null" <|
                \_ ->
                    Expect.equal J.null (Encode.body NoBody)
            , test "encodes TextBody to plain text" <|
                \_ ->
                    Expect.equal
                        (J.string "abc123")
                        (TextBody "abc123" |> Encode.body)
            ]
        , describe "encodeResponse"
            [ testConnWith Fuzz.header "contains the most recent header (when a header is set more than once)" <|
                \( conn, val ) ->
                    let
                        result =
                            conn |> Conn.header val |> Encode.getResponse
                    in
                        case result of
                            Ok resp ->
                                Expect.Extra.member val resp.headers

                            Err err ->
                                Expect.fail err
            ]
        ]
