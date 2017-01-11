module Serverless.Request
    exposing
        ( decode
        , Method
        , Raw
        , Request
        )

{-| Defines an HTTP request.

@docs decode, Method, Raw, Request
-}

import Json.Decode exposing (decodeValue, at)
import Json.Encode


-- MODEL


{-| HTTP request message type
-}
type Method
    = GET
    | POST
    | PUT
    | DELETE
    | OPTIONS


{-| HTTP Request (wip)
-}
type alias Request =
    { method : Method
    , path : String
    }



-- DECODER


{-| A raw HTTP request, before decoding
-}
type alias Raw =
    Json.Encode.Value


{-| Decode a raw HTTP request
-}
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
