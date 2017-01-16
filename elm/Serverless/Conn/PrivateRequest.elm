module Serverless.Conn.PrivateRequest exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, hardcoded)
import Maybe.Extra exposing (combine)
import Serverless.Conn.Request as Request exposing (..)
import Toolkit.Helpers exposing (take4Tuple)


requestDecoder : Json.Decode.Decoder Request
requestDecoder =
    decode Request
        |> required "id" string
        |> required "host" string
        |> required "method" (string |> andThen methodDecoder)
        |> required "path" string
        |> required "port" int
        |> required "remoteIp" (string |> andThen ipDecoder)
        |> required "headers" (keyValuePairs string |> map normalizeHeaders)
        |> required "scheme" (string |> andThen schemeDecoder)
        |> required "stage" string
        |> required "queryParams" (keyValuePairs string)


normalizeHeaders : List ( String, a ) -> List ( String, a )
normalizeHeaders =
    List.map (\( a, b ) -> ( a |> String.toLower, b ))


ipDecoder : String -> Decoder IpAddress
ipDecoder w =
    w
        |> String.split "."
        |> List.map String.toInt
        |> List.map Result.toMaybe
        |> combine
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
