module Serverless.Conn.IpAddress exposing
    ( IpAddress
    , ip4, loopback
    , decoder
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


{-| IP address type.
-}
type IpAddress
    = Ip4 Int Int Int Int



-- CONSTRUCTORS


{-| Creates an IPv4 address.
-}
ip4 : Int -> Int -> Int -> Int -> IpAddress
ip4 =
    Ip4


{-| The loopback address.

    loopback
    --> ip4 127 0 0 1

-}
loopback : IpAddress
loopback =
    Ip4 127 0 0 1



-- JSON


{-| JSON decoder an IP address.
-}
decoder : Decoder IpAddress
decoder =
    Decode.string
        |> andThen
            (\w ->
                let
                    list =
                        w
                            |> String.split "."
                            |> List.map toNonNegativeInt
                in
                case list of
                    (Just a) :: (Just b) :: (Just c) :: (Just d) :: [] ->
                        Decode.succeed (Ip4 a b c d)

                    _ ->
                        Decode.fail <| "Unsupported IP address: " ++ w
            )


toNonNegativeInt : String -> Maybe Int
toNonNegativeInt val =
    val
        |> String.toInt
        |> Maybe.andThen
            (\i ->
                if i >= 0 then
                    Just i

                else
                    Nothing
            )
