module Serverless.Conn.EncodeTests exposing (all)

import Expect
import Expect.Extra as Expect
import Json.Encode as Encode
import Serverless.Conn as Conn
import Serverless.Conn.Encode as Encode
import Serverless.Conn.Fuzz as Fuzz
import Serverless.Conn.Test as Test
import Serverless.Conn.Types exposing (Body(..))
import Test exposing (describe, test)


all : Test.Test
all =
    describe "Serverless.Conn.Encode"
        [ describe "encodeBody"
            [ test "encodes NoBody as null" <|
                \_ ->
                    Expect.equal Encode.null (Encode.body NoBody)
            , test "encodes TextBody to plain text" <|
                \_ ->
                    Expect.equal
                        (Encode.string "abc123")
                        (TextBody "abc123" |> Encode.body)
            ]
        , describe "encodeResponse"
            [ Test.connWith Fuzz.header "contains the most recent header (when a header is set more than once)" <|
                \( conn, val ) ->
                    let
                        result =
                            conn |> Conn.header val |> Encode.getResponse
                    in
                        case result of
                            Ok resp ->
                                Expect.member val resp.headers

                            Err err ->
                                Expect.fail err
            ]
        ]
