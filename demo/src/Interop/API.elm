port module Interop.API exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Serverless
import Serverless.Conn exposing (interop, jsonBody, respond, route)
import UrlParser exposing ((</>), int, map, oneOf, s, top)


{-| Shows how to call JavaScript functions.
-}
main : Serverless.Program () () Route Interop Msg
main =
    Serverless.httpApi
        { configDecoder = Serverless.noConfig
        , initialModel = ()
        , requestPort = requestPort
        , responsePort = responsePort

        -- Route /:lowerBound/:upperBound
        , parseRoute =
            UrlParser.parseString <|
                oneOf
                    [ map NumberRange (int </> int)
                    , map (NumberRange 0) int
                    , map (NumberRange 0 1000000000) top
                    , map Unit (s "unit")
                    ]

        -- Entry point for new connections.
        , endpoint = endpoint

        -- Enumerates JavaScript interop functions and provides JSON coders
        -- to convert data between Elm and JSON.
        , interop = Serverless.Interop encodeInterop interopDecoder

        -- Interop results are handled as side-effects in the update function
        , update = update
        }



-- INTEROP


type Interop
    = GetRandomInt Int Int
    | GetRandomUnit


encodeInterop : Interop -> Encode.Value
encodeInterop interop =
    case interop of
        GetRandomInt lower upper ->
            Encode.object
                [ ( "lower", Encode.int lower )
                , ( "upper", Encode.int upper )
                ]

        GetRandomUnit ->
            Encode.object []


interopDecoder : String -> Maybe (Decoder Msg)
interopDecoder name =
    case name of
        "getRandomInt" ->
            Just <| Decode.map RandomNumber Decode.int

        "getRandomUnit" ->
            Just <| Decode.map RandomFloat Decode.float

        _ ->
            Nothing



-- ROUTING


type Route
    = NumberRange Int Int
    | Unit


endpoint : Conn -> ( Conn, Cmd Msg )
endpoint conn =
    case route conn of
        NumberRange lower upper ->
            interop [ GetRandomInt lower upper ] conn

        Unit ->
            interop [ GetRandomUnit ] conn



-- UPDATE


type Msg
    = RandomNumber Int
    | RandomFloat Float


update : Msg -> Conn -> ( Conn, Cmd Msg )
update msg conn =
    case msg of
        RandomNumber val ->
            respond ( 200, jsonBody <| Encode.int val ) conn

        RandomFloat val ->
            respond ( 200, jsonBody <| Encode.float val ) conn



-- TYPES


type alias Conn =
    Serverless.Conn.Conn () () Route Interop


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg
