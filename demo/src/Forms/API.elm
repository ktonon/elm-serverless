port module Forms.API exposing (main)

import Json.Decode exposing (Decoder, decodeValue, int, map, string)
import Json.Decode.Pipeline exposing (decode, required)
import Serverless
import Serverless.Conn exposing (method, request, respond, textBody)
import Serverless.Conn.Request exposing (Method(..), asJson, body)


{-| Shows one way to convert a JSON POST body into Elm data
-}
main : Serverless.Program () () () () ()
main =
    Serverless.httpApi
        { configDecoder = Serverless.noConfig
        , initialModel = ()
        , parseRoute = Serverless.noRoutes
        , update = Serverless.noSideEffects
        , interop = Serverless.noInterop
        , requestPort = requestPort
        , responsePort = responsePort

        -- Entry point for new connections.
        , endpoint = endpoint
        }


type alias Person =
    { name : String
    , age : Int
    }


endpoint : Conn -> ( Conn, Cmd () )
endpoint conn =
    case
        ( method conn
        , conn
            |> (request >> body >> asJson)
            |> Result.andThen (decodeValue personDecoder)
        )
    of
        ( POST, Ok person ) ->
            respond ( 200, textBody <| toString person ) conn

        ( POST, Err err ) ->
            respond
                ( 400
                , textBody <| "Could not decode request body. " ++ err
                )
                conn

        _ ->
            respond ( 405, textBody "Method not allowed" ) conn


personDecoder : Decoder Person
personDecoder =
    decode Person
        |> required "name" string
        |> required "age" int


type alias Conn =
    Serverless.Conn.Conn () () () ()


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg
