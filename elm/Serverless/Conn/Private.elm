module Serverless.Conn.Private exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Json.Encode as J
import Serverless.Conn.Types exposing (..)
import Toolkit.Helpers exposing (maybeList, take4Tuple)


-- REQUEST DECODER


requestDecoder : Json.Decode.Decoder Request
requestDecoder =
    decode Request
        |> required "id" string
        |> required "body" bodyDecoder
        |> required "headers" (keyValuePairs string |> map normalizeHeaders)
        |> required "host" string
        |> required "method" (string |> andThen methodDecoder)
        |> required "path" string
        |> required "port" int
        |> required "remoteIp" (string |> andThen ipDecoder)
        |> required "scheme" (string |> andThen schemeDecoder)
        |> required "stage" string
        |> required "queryParams" (keyValuePairs string)


bodyDecoder : Decoder Body
bodyDecoder =
    nullable string
        |> andThen
            ((Maybe.map TextBody)
                >> (Maybe.withDefault NoBody)
                >> succeed
            )


normalizeHeaders : List ( String, a ) -> List ( String, a )
normalizeHeaders =
    List.map (\( a, b ) -> ( a |> String.toLower, b ))


ipDecoder : String -> Decoder IpAddress
ipDecoder w =
    w
        |> String.split "."
        |> List.map String.toInt
        |> List.map Result.toMaybe
        |> maybeList
        |> Maybe.andThen take4Tuple
        |> Maybe.map (Ip4 >> succeed)
        |> Maybe.withDefault ("Unsupported IP address: " ++ w |> fail)


methodDecoder : String -> Decoder Method
methodDecoder w =
    case w |> String.toLower of
        "get" ->
            succeed GET

        "post" ->
            succeed POST

        "put" ->
            succeed PUT

        "delete" ->
            succeed DELETE

        "options" ->
            succeed OPTIONS

        _ ->
            fail ("Unsupported method: " ++ w)


schemeDecoder : String -> Decoder Scheme
schemeDecoder w =
    case w |> String.toLower of
        "http" ->
            succeed (Http Insecure)

        "https" ->
            succeed (Http Secure)

        _ ->
            fail ("Unsupported scheme: " ++ w)



-- RESPONSE ENCODER


initResponse : Response
initResponse =
    Response
        (InvalidStatusCode)
        NoBody


encodeResponse : Id -> Response -> J.Value
encodeResponse id res =
    J.object
        [ ( "id", J.string id )
        , ( "statusCode", encodeStatusCode res.statusCode )
        , ( "body", encodeBody res.body )
        ]


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


encodeBody : Body -> J.Value
encodeBody body =
    case body of
        NoBody ->
            J.null

        TextBody w ->
            J.string w
