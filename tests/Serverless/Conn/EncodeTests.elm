module Serverless.Conn.EncodeTests exposing (all)

import Expect
import Expect.Extra as Expect exposing (stringPattern)
import Json.Encode as Encode
import Serverless.Conn as Conn exposing (updateResponse)
import Serverless.Conn.Body as Body
import Serverless.Conn.Response as Response exposing (addHeader)
import Serverless.Conn.Test as Test
import Test exposing (describe, test)


all : Test.Test
all =
    describe "Serverless.Conn.Encode"
        [ describe "encodeBody"
            [ test "encodes NoBody as null" <|
                \_ ->
                    Expect.equal Encode.null (Body.encode Body.empty)
            , test "encodes TextBody to plain text" <|
                \_ ->
                    Expect.equal
                        (Encode.string "abc123")
                        (Body.text "abc123" |> Body.encode)
            ]
        , describe "encodeResponse"
            [ Test.conn "contains the most recent header (when a header is set more than once)" <|
                updateResponse
                    (addHeader ( "content-type", "text/text" )
                        >> addHeader ( "content-type", "application/xml" )
                    )
                    >> Conn.jsonEncodedResponse
                    >> Encode.encode 0
                    >> Expect.match
                        (stringPattern "\"content-type\":\"application/xml\"")
            ]
        ]
