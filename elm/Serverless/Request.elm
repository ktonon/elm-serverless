module Serverless.Request exposing (..)

import Json.Decode exposing (decodeValue, at)
import Json.Encode


-- MODEL


type Method
    = GET
    | POST
    | PUT
    | DELETE
    | OPTIONS


type alias Request =
    { method : Method
    , path : String
    }



-- DECODER


type alias Raw =
    Json.Encode.Value


decode : Raw -> Result String Request
decode data =
    Json.Decode.decodeValue decoder data


decoder : Json.Decode.Decoder Request
decoder =
    Json.Decode.map2 Request
        (at [ "method" ] Json.Decode.string |> Json.Decode.andThen decodeMethod)
        (at [ "path" ] Json.Decode.string)


decodeMethod : String -> Json.Decode.Decoder Method
decodeMethod w =
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
