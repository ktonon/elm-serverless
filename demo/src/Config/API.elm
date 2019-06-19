port module Config.API exposing (main)

import Json.Decode exposing (Decoder, andThen, fail, int, map, string, succeed)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
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
                    , textBody <| (++) "Config: " <| configToString (config conn)
                    )
                    conn
        }



-- CONFIG TYPES


configToString : Config -> String
configToString config =
    Encode.encode 0 (configEncoder config)


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
    succeed Config
        |> required "auth" (succeed Auth |> required "secret" string)
        |> required "someService" serviceDecoder


authEncoder : Auth -> Encode.Value
authEncoder auth =
    [ ( "secret", Encode.string auth.secret ) ]
        |> Encode.object


configEncoder : Config -> Encode.Value
configEncoder config =
    [ ( "auth", authEncoder config.auth )
    , ( "someService", serviceEncoder config.someService )
    ]
        |> Encode.object


serviceDecoder : Decoder Service
serviceDecoder =
    succeed Service
        |> required "protocol" protocolDecoder
        |> required "host" string
        |> required "port" (string |> andThen (String.toInt >> maybeToDecoder))


serviceEncoder : Service -> Encode.Value
serviceEncoder service =
    [ ( "protocol", protocolEncoder service.protocol )
    , ( "host", Encode.string service.host )
    , ( "port", Encode.int service.port_ )
    ]
        |> Encode.object


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


protocolEncoder : Protocol -> Encode.Value
protocolEncoder protocol =
    case protocol of
        Http ->
            Encode.string "http"

        Https ->
            Encode.string "https"


maybeToDecoder : Maybe a -> Decoder a
maybeToDecoder maybe =
    case maybe of
        Just val ->
            succeed val

        Nothing ->
            fail "nothing"


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg
