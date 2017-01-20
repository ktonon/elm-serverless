module Conn.Fuzz exposing (..)

import Conn.Shrink
import Custom exposing (..)
import Fuzz exposing (Fuzzer, map, andMap, andThen)
import Fuzz.Extra
import Serverless.Conn.Types exposing (..)
import Shrink


conn : Fuzzer (Conn Config Model)
conn =
    Fuzz.map4 Conn
        config
        request
        response
        model


config : Fuzzer Config
config =
    Fuzz.map Config Fuzz.string


model : Fuzzer Model
model =
    Fuzz.map Model Fuzz.int


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


id : Fuzzer Id
id =
    Fuzz.string


body : Fuzzer Body
body =
    Fuzz.Extra.eitherOr (Fuzz.constant NoBody) textBody


textBody : Fuzzer Body
textBody =
    Fuzz.string |> map TextBody


headers : Fuzzer (List ( String, String ))
headers =
    (Fuzz.map2 (,) Fuzz.string Fuzz.string)
        |> Fuzz.list


host : Fuzzer String
host =
    Fuzz.Extra.union
        [ "localhost", "example.com", "sub.dom.ain.tv", "with.a9.num8er.ca" ]
        ""
        Shrink.string


method : Fuzzer Method
method =
    Fuzz.Extra.union [ GET, POST, PUT, DELETE, OPTIONS ] GET Conn.Shrink.method


path : Fuzzer String
path =
    Fuzz.string


port_ : Fuzzer Int
port_ =
    Fuzz.intRange 80 9999


scheme : Fuzzer Scheme
scheme =
    secure |> map Http


secure : Fuzzer Secure
secure =
    Fuzz.Extra.eitherOr (Fuzz.constant Secure) (Fuzz.constant Insecure)


ipAddress : Fuzzer IpAddress
ipAddress =
    (Fuzz.map4
        (\a b c d -> ( a, b, c, d ))
        Fuzz.int
        Fuzz.int
        Fuzz.int
        Fuzz.int
    )
        |> map Ip4


status : Fuzzer Status
status =
    Fuzz.Extra.eitherOr (Fuzz.constant InvalidStatus) validStatus


stage : Fuzzer String
stage =
    Fuzz.Extra.union
        [ "dev", "prod", "staging" ]
        ""
        Shrink.string


validStatus : Fuzzer Status
validStatus =
    Fuzz.intRange 200 599 |> map Code


charset : Fuzzer Charset
charset =
    Fuzz.constant Utf8


queryParams : Fuzzer (List ( String, String ))
queryParams =
    headers
