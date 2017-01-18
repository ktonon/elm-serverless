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
        |> required "headers" (paramsDecoder |> map normalizeHeaders)
        |> required "host" string
        |> required "method" methodDecoder
        |> required "path" string
        |> required "port" int
        |> required "remoteIp" ipDecoder
        |> required "scheme" schemeDecoder
        |> required "stage" string
        |> required "queryParams" paramsDecoder


paramsDecoder : Decoder (List ( String, String ))
paramsDecoder =
    keyValuePairs string
        |> nullable
        |> andThen
            (\maybeParams ->
                case maybeParams of
                    Just params ->
                        succeed params

                    Nothing ->
                        succeed []
            )


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


ipDecoder : Decoder IpAddress
ipDecoder =
    string |> andThen ipDecoderHelper


ipDecoderHelper : String -> Decoder IpAddress
ipDecoderHelper w =
    w
        |> String.split "."
        |> List.map toNonNegativeInt
        |> maybeList
        |> require4
        |> Maybe.andThen take4Tuple
        |> Maybe.map (Ip4 >> succeed)
        |> Maybe.withDefault ("Unsupported IP address: " ++ w |> fail)


toNonNegativeInt : String -> Maybe Int
toNonNegativeInt val =
    case val |> String.toInt of
        Ok i ->
            if i >= 0 then
                Just i
            else
                Nothing

        Err _ ->
            Nothing


require4 : Maybe (List a) -> Maybe (List a)
require4 maybeList =
    case maybeList of
        Just list ->
            if (List.length list) == 4 then
                Just list
            else
                Nothing

        Nothing ->
            Nothing


methodDecoder : Decoder Method
methodDecoder =
    string |> andThen methodDecoderHelper


methodDecoderHelper : String -> Decoder Method
methodDecoderHelper w =
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


schemeDecoder : Decoder Scheme
schemeDecoder =
    string |> andThen schemeDecoderHelper


schemeDecoderHelper : String -> Decoder Scheme
schemeDecoderHelper w =
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
