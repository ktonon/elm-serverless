port module Quoted.Types exposing (Config, Conn, Interop(..), Msg(..), Plug, Quote, configDecoder, interopDecoder, interopEncode, requestPort, responsePort)

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, hardcoded, required)
import Json.Encode as Encode
import Quoted.Route exposing (Route)
import Serverless
import Serverless.Conn exposing (Id)
import Serverless.Plug



-- CUSTOM TYPES
--
-- The following (Config, Model, and Msg) are required by Serverless.Program,
-- but can be defined as anything you want.


{-| Can be anything you want, you just need to provide a decoder
-}
type alias Config =
    { languages : List String
    , enableAuth : Bool
    }


configDecoder : Decoder Config
configDecoder =
    decode Config
        |> required "languages" (Decode.list Decode.string)
        |> required "enableAuth" (Decode.string |> Decode.map ((==) "true"))


type alias Quote =
    { lang : String
    , text : String
    , author : String
    }


{-| Your custom message type.

The only restriction is that it has to contain an endpoint. You can call the
endpoint whatever you want, but it accepts no parameters, and must be provided
to the program as `endpoint` (see above).

-}
type Msg
    = GotQuotes (Result Http.Error (List Quote))
    | RandomNumber Int


{-| Your custom interop type.

Should enumerate the interop (JavaScript) functions which can be called.

-}
type Interop
    = GetRandom Int


interopEncode : Interop -> Encode.Value
interopEncode interop =
    case interop of
        GetRandom upper ->
            Encode.int upper


interopDecoder : String -> Maybe (Decode.Decoder Msg)
interopDecoder interopName =
    case interopName of
        "getRandom" ->
            Just <| Decode.map RandomNumber Decode.int

        _ ->
            Nothing



-- SERVERLESS TYPES
--
-- Provide concrete values for the type variable defined in Serverless.Types
-- then import this module instead, to make your code more readable.


type alias Conn =
    Serverless.Conn.Conn Config () Route Interop


type alias Plug =
    Serverless.Plug.Plug Config () Route Interop


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg
