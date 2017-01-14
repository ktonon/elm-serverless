module Serverless.Conn.PrivateRequest exposing (..)

import Json.Decode exposing (decodeValue, at)
import Serverless.Conn.Request as Request exposing (..)


requestDecoder : Json.Decode.Decoder Request
requestDecoder =
    Json.Decode.map4 Request
        (at [ "id" ] Json.Decode.string)
        (at [ "method" ] Json.Decode.string |> Json.Decode.andThen methodDecoder)
        (at [ "path" ] Json.Decode.string)
        (at [ "stage" ] Json.Decode.string)


methodDecoder : String -> Json.Decode.Decoder Method
methodDecoder w =
    case w |> String.toLower of
        "get" ->
            Json.Decode.succeed GET

        "post" ->
            Json.Decode.succeed POST

        "put" ->
            Json.Decode.succeed PUT

        "delete" ->
            Json.Decode.succeed DELETE

        "options" ->
            Json.Decode.succeed OPTIONS

        _ ->
            Json.Decode.fail ("Bad method: " ++ w)
