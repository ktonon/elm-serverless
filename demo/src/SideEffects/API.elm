port module SideEffects.API exposing (..)

import Json.Encode
import Random
import Serverless
import Serverless.Conn exposing (jsonBody, respond, route)
import UrlParser exposing ((</>), int, map, oneOf, s, top)


{-| Shows how to use the update function to handle side-effects.
-}
main : Serverless.Program () () Route () Msg
main =
    Serverless.httpApi
        { configDecoder = Serverless.noConfig
        , initialModel = ()
        , interop = Serverless.noInterop
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

        -- Incoming connection handler
        , endpoint = endpoint

        -- Like a SPA update function, but operates on Conn
        , update = update
        }



-- ROUTING


type Route
    = NumberRange Int Int
    | Unit


endpoint : Conn -> ( Conn, Cmd Msg )
endpoint conn =
    case route conn of
        NumberRange lower upper ->
            ( -- Leave connection unmodified
              conn
            , -- Issues a command. The result will come into the update
              -- function as the RandomNumber message
              Random.generate RandomNumber <|
                Random.int lower upper
            )

        Unit ->
            ( conn
            , Random.generate RandomFloat <|
                Random.float 0 1
            )



-- UPDATE


type Msg
    = RandomNumber Int
    | RandomFloat Float


update : Msg -> Conn -> ( Conn, Cmd Msg )
update msg conn =
    case msg of
        RandomNumber val ->
            respond ( 200, jsonBody <| Json.Encode.int val ) conn

        RandomFloat val ->
            respond ( 200, jsonBody <| Json.Encode.float val ) conn



-- TYPES


type alias Conn =
    Serverless.Conn.Conn () () Route ()


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg
