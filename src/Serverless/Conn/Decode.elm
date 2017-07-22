module Serverless.Conn.Decode
    exposing
        ( body
        , ip
        , method
        , params
        , request
        , response
        , scheme
        )

import Json.Decode as Decode exposing (Decoder, andThen, map)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Serverless.Conn.Types exposing (..)
import Toolkit.Helpers exposing (maybeList, take4Tuple)


request : Decoder Request
request =
    decode Request
        |> required "id" Decode.string
        |> required "body" body
        |> required "headers" (params |> map normalizeHeaders)
        |> required "host" Decode.string
        |> required "method" method
        |> required "path" Decode.string
        |> required "port" Decode.int
        |> required "remoteIp" ip
        |> required "scheme" scheme
        |> required "stage" Decode.string
        |> required "queryParams" params


params : Decoder (List ( String, String ))
params =
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


body : Decoder Body
body =
    Decode.nullable Decode.string
        |> andThen
            ((Maybe.map TextBody)
                >> (Maybe.withDefault NoBody)
                >> Decode.succeed
            )


normalizeHeaders : List ( String, a ) -> List ( String, a )
normalizeHeaders =
    List.map (\( a, b ) -> ( a |> String.toLower, b ))


ip : Decoder IpAddress
ip =
    Decode.string
        |> andThen
            (\w ->
                w
                    |> String.split "."
                    |> List.map toNonNegativeInt
                    |> maybeList
                    |> require4
                    |> Maybe.andThen take4Tuple
                    |> Maybe.map (Decode.succeed << Ip4)
                    |> Maybe.withDefault (Decode.fail <| "Unsupported IP address: " ++ w)
            )


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


method : Decoder Method
method =
    Decode.string
        |> andThen
            (\w ->
                case w |> String.toLower of
                    "get" ->
                        Decode.succeed GET

                    "post" ->
                        Decode.succeed POST

                    "put" ->
                        Decode.succeed PUT

                    "delete" ->
                        Decode.succeed DELETE

                    "options" ->
                        Decode.succeed OPTIONS

                    _ ->
                        Decode.fail ("Unsupported method: " ++ w)
            )


scheme : Decoder Scheme
scheme =
    Decode.string
        |> andThen
            (\w ->
                case w |> String.toLower of
                    "http" ->
                        Decode.succeed (Http Insecure)

                    "https" ->
                        Decode.succeed (Http Secure)

                    _ ->
                        Decode.fail ("Unsupported scheme: " ++ w)
            )



-- RESPONSE DECODER


response : Decoder Response
response =
    decode Response
        |> required "body" body
        |> required "charset" charset
        |> required "headers" (params |> map normalizeHeaders)
        |> required "statusCode" status


charset : Decoder Charset
charset =
    Decode.string
        |> andThen
            (\w ->
                if (w |> String.toLower) == "utf8" then
                    Decode.succeed Utf8
                else
                    Decode.fail ("Unsupported charset: " ++ w)
            )


status : Decoder Status
status =
    Decode.int
        |> andThen
            (\c ->
                Decode.succeed <|
                    if c < 200 || c > 599 then
                        InvalidStatus
                    else
                        Code c
            )
