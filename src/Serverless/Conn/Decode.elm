module Serverless.Conn.Decode exposing (..)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Serverless.Conn.Types exposing (..)
import Toolkit.Helpers exposing (maybeList, take4Tuple)


request : Json.Decode.Decoder Request
request =
    decode Request
        |> required "id" string
        |> required "body" body
        |> required "headers" (params |> map normalizeHeaders)
        |> required "host" string
        |> required "method" method
        |> required "path" string
        |> required "port" int
        |> required "remoteIp" ip
        |> required "scheme" scheme
        |> required "stage" string
        |> required "queryParams" params


params : Decoder (List ( String, String ))
params =
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


body : Decoder Body
body =
    nullable string
        |> andThen
            ((Maybe.map TextBody)
                >> (Maybe.withDefault NoBody)
                >> succeed
            )


normalizeHeaders : List ( String, a ) -> List ( String, a )
normalizeHeaders =
    List.map (\( a, b ) -> ( a |> String.toLower, b ))


ip : Decoder IpAddress
ip =
    string
        |> andThen
            (\w ->
                w
                    |> String.split "."
                    |> List.map toNonNegativeInt
                    |> maybeList
                    |> require4
                    |> Maybe.andThen take4Tuple
                    |> Maybe.map (Ip4 >> succeed)
                    |> Maybe.withDefault ("Unsupported IP address: " ++ w |> fail)
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
    string
        |> andThen
            (\w ->
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
            )


scheme : Decoder Scheme
scheme =
    string
        |> andThen
            (\w ->
                case w |> String.toLower of
                    "http" ->
                        succeed (Http Insecure)

                    "https" ->
                        succeed (Http Secure)

                    _ ->
                        fail ("Unsupported scheme: " ++ w)
            )



-- RESPONSE ENCODER


response : Decoder Response
response =
    decode Response
        |> required "body" body
        |> required "charset" charset
        |> required "headers" (params |> map normalizeHeaders)
        |> required "statusCode" status


charset : Decoder Charset
charset =
    string
        |> andThen
            (\w ->
                if (w |> String.toLower) == "utf8" then
                    succeed Utf8
                else
                    fail ("Unsupported charset: " ++ w)
            )


status : Decoder Status
status =
    int
        |> andThen
            (\c ->
                if c < 200 || c > 599 then
                    succeed InvalidStatus
                else
                    succeed (Code c)
            )
