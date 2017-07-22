module Serverless.Conn.Fuzz
    exposing
        ( body
        , conn
        , header
        , request
        , status
        )

import Fuzz exposing (Fuzzer, map, andMap, andThen, constant)
import Fuzz.Extra exposing (eitherOr)
import Serverless.Conn.Types exposing (..)
import Serverless.TestTypes exposing (Config, Conn, Model)
import Serverless.Types exposing (PipelineState(..), Sendable(..))


conn : Fuzzer Conn
conn =
    Fuzz.map5 Serverless.Types.Conn
        (constant Processing)
        (constant (Config "secret"))
        request
        unsentResponse
        (constant (Model 0))



-- response


unsentResponse : Fuzzer (Sendable Response)
unsentResponse =
    response |> map Unsent


response : Fuzzer Response
response =
    Fuzz.map4 Response
        body
        (constant Utf8)
        headers
        status



-- request


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
        |> andMap (constant 3000)
        |> andMap (constant (Ip4 ( 127, 0, 0, 1 )))
        |> andMap (map Http secure)
        |> andMap (constant "dev")
        |> andMap queryParams


id : Fuzzer Id
id =
    constant "8d66a836-6e4e-11e7-907b-a6006ad3dba0"


body : Fuzzer Body
body =
    eitherOr
        (constant NoBody)
        textBody


textBody : Fuzzer Body
textBody =
    constant (TextBody "some text body")


headers : Fuzzer (List ( String, String ))
headers =
    eitherOr
        (constant [])
        (map toList header)


header : Fuzzer ( String, String )
header =
    constant ( "some-header", "Some Value" )


host : Fuzzer String
host =
    eitherOr
        (constant "localhost")
        (constant "sub.dom.ain.tv")


method : Fuzzer Method
method =
    eitherOr
        (constant GET)
        (constant POST)


path : Fuzzer String
path =
    eitherOr
        (constant "/")
        (constant "/foo/bar-dy/8/car_dy")


secure : Fuzzer Secure
secure =
    eitherOr
        (constant Secure)
        (constant Insecure)


status : Fuzzer Status
status =
    eitherOr
        (constant InvalidStatus)
        (constant (Code 200))


queryParams : Fuzzer (List ( String, String ))
queryParams =
    eitherOr
        (constant [])
        (constant [ ( "page", "123" ) ])



-- helpers


toList : a -> List a
toList =
    \x -> [ x ]
