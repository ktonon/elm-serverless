module Serverless.Conn.KeyValueList exposing (decoder, encode)

import Json.Decode as Decode exposing (Decoder, andThen, map)
import Json.Encode as Encode


decoder : Decoder (List ( String, String ))
decoder =
    Decode.keyValuePairs Decode.string
        |> Decode.nullable
        |> andThen
            (\maybeParams ->
                case maybeParams of
                    Just params ->
                        Decode.succeed params

                    Nothing ->
                        Decode.succeed []
            )


encode : List ( String, String ) -> Encode.Value
encode params =
    params
        |> List.reverse
        |> List.map (\( a, b ) -> ( a, Encode.string b ))
        |> Encode.object
