module Serverless.Conn.Charset exposing
    ( Charset
    , default, utf8
    , toString
    )

{-| A character encoding.

@docs Charset

@docs default, utf8

@docs toString

-}


{-| -}
type Charset
    = Utf8



-- CONSTRUCTORS


{-| -}
default : Charset
default =
    Utf8


{-| -}
utf8 : Charset
utf8 =
    Utf8



-- QUERY


{-| -}
toString : Charset -> String
toString charset =
    case charset of
        Utf8 ->
            "utf-8"
