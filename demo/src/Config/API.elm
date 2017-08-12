port module Config.API exposing (..)

import Json.Decode exposing (Decoder, andThen, fail, int, map, string, succeed)
import Json.Decode.Pipeline exposing (decode, required)
import Serverless
import Serverless.Conn exposing (config, respond, textBody)


{-| Shows how to load per-instance configuration.
-}
main : Serverless.Program Config () () () ()
main =
    Serverless.httpApi
        { initialModel = ()
        , parseRoute = Serverless.noRoutes
        , update = Serverless.noSideEffects
        , interop = Serverless.noInterop
        , requestPort = requestPort
        , responsePort = responsePort

        -- Decodes per instance configuration into Elm data. If decoding fails
        -- the server will return 500 for every request and log details about
        -- the failure. This decoder is called once at startup.
        , configDecoder = configDecoder

        -- Once we get here, we can be sure that the config has been parsed
        -- into Elm data, and can be accessed using `Conn.config`
        , endpoint =
            \conn ->
                respond
                    ( 200
                    , textBody <| (++) "Config: " <| toString (config conn)
                    )
                    conn
        }



-- CONFIG TYPES


type alias Config =
    { auth : Auth
    , someService : Service
    }


type alias Auth =
    { secret : String }


type alias Service =
    { protocol : Protocol
    , host : String
    , port_ : Int
    }


type Protocol
    = Http
    | Https



-- DECODERS


configDecoder : Decoder Config
configDecoder =
    decode Config
        |> required "auth" (decode Auth |> required "secret" string)
        |> required "someService" serviceDecoder


serviceDecoder : Decoder Service
serviceDecoder =
    decode Service
        |> required "protocol" protocolDecoder
        |> required "host" string
        |> required "port" (string |> andThen (String.toInt >> resultToDecoder))


protocolDecoder : Decoder Protocol
protocolDecoder =
    andThen
        (\w ->
            case String.toLower w of
                "http" ->
                    succeed Http

                "https" ->
                    succeed Https

                _ ->
                    fail ""
        )
        string


resultToDecoder : Result err a -> Decoder a
resultToDecoder result =
    case result of
        Ok val ->
            succeed val

        Err err ->
            fail (toString err)


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg
