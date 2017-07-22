module Serverless.Conn.Encode exposing (getResponse, response, body)

import Json.Decode exposing (decodeValue)
import Json.Encode as Encode
import Serverless.Conn.Decode as Decode
import Serverless.Conn.Types exposing (Body(..), Charset, Id, Response, Status(..))
import Serverless.Types exposing (Conn, Sendable(..))


getResponse : Conn config model -> Result String Response
getResponse conn =
    case conn.resp of
        Unsent resp ->
            resp
                |> response conn.req.id
                |> decodeValue Decode.response

        Sent ->
            Err "response already sent"


response : Id -> Response -> Encode.Value
response id res =
    Encode.object
        [ ( "id", Encode.string id )
        , ( "body", body res.body )
        , ( "charset", charset res.charset )
        , ( "headers", res.headers |> List.reverse |> params )
        , ( "statusCode", status res.status )
        ]


body : Body -> Encode.Value
body body =
    case body of
        NoBody ->
            Encode.null

        TextBody w ->
            Encode.string w

        JsonBody j ->
            j


charset : Charset -> Encode.Value
charset =
    toString
        >> String.toLower
        >> Encode.string


params : List ( String, String ) -> Encode.Value
params =
    List.map (\( a, b ) -> ( a, Encode.string b ))
        >> Encode.object


status : Status -> Encode.Value
status status =
    case status of
        InvalidStatus ->
            Encode.int -1

        Code code ->
            Encode.int code
