module Serverless.Conn.IpAddress
    exposing
        ( IpAddress
        , decoder
        , ip4
        , loopback
        )

{-| Internet protocol addresses and related functions.

@docs IpAddress


## Constructors

@docs ip4, loopback


## Misc

These functions are typically not needed when building an application. They are
used internally by the framework.

@docs decoder

-}

import Json.Decode as Decode exposing (Decoder, andThen)
import Toolkit.Helpers exposing (maybeList, take4Tuple)


{-| IP address type.
-}
type IpAddress
    = Ip4 ( Int, Int, Int, Int )



-- CONSTRUCTORS


{-| Creates an IPv4 address.
-}
ip4 : Int -> Int -> Int -> Int -> IpAddress
ip4 a b c d =
    Ip4 ( a, b, c, d )


{-| The loopback address.

    loopback
    --> ip4 127 0 0 1

-}
loopback : IpAddress
loopback =
    Ip4 ( 127, 0, 0, 1 )



-- JSON


{-| JSON decoder an IP address.
-}
decoder : Decoder IpAddress
decoder =
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
            if List.length list == 4 then
                Just list
            else
                Nothing

        Nothing ->
            Nothing
