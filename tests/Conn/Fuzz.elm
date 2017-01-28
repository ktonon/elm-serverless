module Conn.Fuzz exposing (..)

import Custom exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, map, andMap, andThen, constant)
import Fuzz.Extra exposing (..)
import Serverless.Conn.Types exposing (..)
import Test exposing (Test)


testConn : String -> (Custom.Conn -> Expectation) -> Test
testConn label =
    Test.fuzz conn label


testConnWith : Fuzzer a -> String -> (( Custom.Conn, a ) -> Expectation) -> Test
testConnWith otherFuzzer label =
    Test.fuzz (Fuzz.tuple ( conn, otherFuzzer )) label


conn : Fuzzer Custom.Conn
conn =
    Fuzz.map5 Conn
        pipelineState
        config
        request
        unsentResponse
        model


pipelineState : Fuzzer PipelineState
pipelineState =
    Processing |> constant


config : Fuzzer Config
config =
    "secret" |> constant |> Fuzz.map Config


model : Fuzzer Model
model =
    0 |> constant |> Fuzz.map Model


request : Fuzzer Request
request =
    (Fuzz.map5 Request
        id
        body
        headers
        host
        method
    )
        |> andMap path
        |> andMap port_
        |> andMap ipAddress
        |> andMap scheme
        |> andMap stage
        |> andMap queryParams


response : Fuzzer Response
response =
    Fuzz.map4 Response
        body
        charset
        headers
        status


unsentResponse : Fuzzer (Sendable Response)
unsentResponse =
    response |> Fuzz.map Unsent


halted : Fuzzer Bool
halted =
    False |> constant


id : Fuzzer Id
id =
    stringMaxLength 10


body : Fuzzer Body
body =
    eitherOr (constant NoBody) textBody


textBody : Fuzzer Body
textBody =
    "some body" |> constant |> map TextBody


header : Fuzzer ( String, String )
header =
    Fuzz.tuple
        ( [ "content-type", "content-length" ] |> List.map constant |> uniformOrCrash
        , [ "foo", "bar", "car" ] |> List.map constant |> uniformOrCrash
        )


headers : Fuzzer (List ( String, String ))
headers =
    [ constant []
    , header |> map (\h -> [ h ])
    , ( header, header ) |> Fuzz.tuple |> map (\( h0, h1 ) -> [ h0, h1 ])
    ]
        |> uniformOrCrash


host : Fuzzer String
host =
    [ "localhost", "example.com", "sub.dom.ain.tv", "with.a9.num8er.ca" ]
        |> List.map constant
        |> uniformOrCrash


method : Fuzzer Method
method =
    [ GET, POST, PUT, DELETE, OPTIONS ]
        |> List.map constant
        |> uniformOrCrash


path : Fuzzer String
path =
    [ "/", "/foo", "/foo/bar-dy/8/car_dy" ]
        |> List.map constant
        |> uniformOrCrash


port_ : Fuzzer Int
port_ =
    [ 80, 443, 3000 ]
        |> List.map constant
        |> uniformOrCrash


scheme : Fuzzer Scheme
scheme =
    secure |> map Http


secure : Fuzzer Secure
secure =
    eitherOr (constant Secure) (constant Insecure)


ipAddress : Fuzzer IpAddress
ipAddress =
    (Fuzz.map4
        (\a b c d -> ( a, b, c, d ))
        (Fuzz.intRange 0 255)
        (Fuzz.intRange 0 255)
        (Fuzz.intRange 0 255)
        (Fuzz.intRange 0 255)
    )
        |> map Ip4


status : Fuzzer Status
status =
    eitherOr (constant InvalidStatus) validStatus


stage : Fuzzer String
stage =
    [ "dev", "prod", "staging" ]
        |> List.map constant
        |> uniformOrCrash


validStatus : Fuzzer Status
validStatus =
    [ 200, 302, 400, 404, 500 ]
        |> List.map constant
        |> uniformOrCrash
        |> map Code


charset : Fuzzer Charset
charset =
    constant Utf8


queryParam : Fuzzer ( String, String )
queryParam =
    Fuzz.tuple
        ( [ "page", "filter", "_bust" ] |> List.map constant |> uniformOrCrash
        , [ "abc", "123", "foo%20bar" ] |> List.map constant |> uniformOrCrash
        )


queryParams : Fuzzer (List ( String, String ))
queryParams =
    [ constant []
    , queryParam |> map (\h -> [ h ])
    , ( queryParam, queryParam ) |> Fuzz.tuple |> map (\( h0, h1 ) -> [ h0, h1 ])
    ]
        |> uniformOrCrash
