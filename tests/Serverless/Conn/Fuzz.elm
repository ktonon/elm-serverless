module Serverless.Conn.Fuzz exposing
    ( body
    , conn
    , header
    , request
    , status
    )

import Fuzz exposing (Fuzzer, andMap, constant, map)
import Fuzz.Extra exposing (eitherOr)
import Serverless.Conn exposing (Id)
import Serverless.Conn.Body as Body exposing (Body)
import Serverless.Conn.Request as Request exposing (Method(..), Request)
import Serverless.Conn.Response as Response exposing (Response, Status)
import TestHelpers exposing (Config, Conn, Model, Route(..))


conn : Fuzzer Conn
conn =
    Fuzz.map5 Serverless.Conn.init
        id
        (constant (Config "secret"))
        (constant (Model 0))
        (constant Home)
        request



-- response


response : Fuzzer Response
response =
    constant Response.init



-- request


request : Fuzzer Request
request =
    constant Request.init


id : Fuzzer Id
id =
    constant "8d66a836-6e4e-11e7-907b-a6006ad3dba0"


body : Fuzzer Body
body =
    eitherOr
        (constant Body.empty)
        textBody


textBody : Fuzzer Body
textBody =
    constant (Body.text "some text body")


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


status : Fuzzer Status
status =
    constant 200


queryParams : Fuzzer (List ( String, String ))
queryParams =
    eitherOr
        (constant [])
        (constant [ ( "page", "123" ) ])



-- helpers


toList : a -> List a
toList =
    \x -> [ x ]
