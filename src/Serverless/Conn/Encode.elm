module Serverless.Conn.Encode exposing (..)

import Json.Decode
import Json.Encode as J
import Serverless.Conn.Decode
import Serverless.Conn.Types exposing (Body(..), Charset, Id, Response, Status(..))
import Serverless.Types exposing (Conn, Sendable(..))


getResponse : Conn config model -> Result String Response
getResponse conn =
    case conn.resp of
        Unsent resp ->
            resp
                |> response conn.req.id
                |> Json.Decode.decodeValue Serverless.Conn.Decode.response

        Sent ->
            Err "response already sent"


response : Id -> Response -> J.Value
response id res =
    J.object
        [ ( "id", J.string id )
        , ( "body", body res.body )
        , ( "charset", charset res.charset )
        , ( "headers", res.headers |> List.reverse |> params )
        , ( "statusCode", status res.status )
        ]


body : Body -> J.Value
body body =
    case body of
        NoBody ->
            J.null

        TextBody w ->
            J.string w

        JsonBody j ->
            j


charset : Charset -> J.Value
charset =
    toString >> String.toLower >> J.string


params : List ( String, String ) -> J.Value
params params =
    params
        |> List.map (\( a, b ) -> ( a, J.string b ))
        |> J.object


status : Status -> J.Value
status status =
    case status of
        InvalidStatus ->
            J.int -1

        Code code ->
            J.int code
