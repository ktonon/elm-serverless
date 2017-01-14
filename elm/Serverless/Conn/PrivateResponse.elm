module Serverless.Conn.PrivateResponse exposing (..)

import Json.Encode as J
import Serverless.Conn.Request as Request exposing (..)
import Serverless.Conn.Response as Response exposing (..)


initResponse : Response
initResponse =
    Response
        (InvalidStatusCode)
        (TextBody "")


encodeResponse : Request.Id -> Response -> J.Value
encodeResponse id res =
    J.object
        [ ( "id", J.string id )
        , ( "statusCode", encodeStatusCode res.statusCode )
        , ( "body", encodeBody res.body )
        ]


encodeBody : Body -> J.Value
encodeBody body =
    case body of
        TextBody w ->
            J.string w


encodeStatusCode : StatusCode -> J.Value
encodeStatusCode statusCode =
    case statusCode of
        InvalidStatusCode ->
            J.int -1

        NumericStatusCode code ->
            J.int code

        Ok_200 ->
            J.int 200

        NotFound_404 ->
            J.int 404
