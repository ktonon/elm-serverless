port module API exposing (..)

import Json.Decode
import Serverless
import Serverless.Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Plug as Plug exposing (..)


{-| A Serverless.Program is parameterized by your 3 custom types

* Config is a server load-time record of deployment specific values
* Model is for whatever you need during the processing of a request
* Msg is your app message type
-}
main : Serverless.Program Config Model Msg
main =
    Serverless.httpApi
        { configDecoder = configDecoder
        , requestPort = requestPort
        , responsePort = responsePort
        , endpoint = Endpoint
        , initialModel = Model 0
        , pipeline = pipeline
        , subscriptions = subscriptions
        }



-- MODEL


{-| Serverless.Conn.Conn is short for connection.

It is parameterized by the Config and Model record types.
For convenience we create an alias.
-}
type alias Conn =
    Serverless.Conn.Types.Conn Config Model


{-| Can be anything you want, you just need to provide a decoder
-}
type alias Config =
    { something : String
    }


{-| Can be anything you want.
This will get set to initialModel (see above) for each incomming connection.
-}
type alias Model =
    { counter : Int
    }


configDecoder : Json.Decode.Decoder Config
configDecoder =
    Json.Decode.map Config (Json.Decode.at [ "something" ] Json.Decode.string)



-- UPDATE


{-| Your custom message type.

The only restriction is that it has to contain an endpoint. You can call the
endpoint whatever you want, but it accepts no parameters, and must be provided
to the program as `endpoint` (see above).
-}
type Msg
    = Endpoint


pipeline : Pipeline Config Model Msg
pipeline =
    Plug.pipeline
        |> plug (header ( "cache-control", "max-age=guess, preventative, must-reconsider" ))
        |> plug (header ( "cache-control", "this will override the previous one" ))
        |> nest otherPipeline
        |> loop update


otherPipeline : Pipeline Config Model Msg
otherPipeline =
    Plug.pipeline
        |> plug (header ( "pipelines", "can" ))
        |> plug (header ( "be", "nested" ))


update : Msg -> Conn -> ( Conn, Cmd Msg )
update msg conn =
    case msg of
        -- The endpoint signals the start of a new connection.
        -- You don't have to send a response right away, but we do here to
        -- keep the example simple.
        Endpoint ->
            conn
                |> status (Code 200)
                |> body ("Got request:\n" ++ (toString conn.req) |> TextBody)
                |> header ( "content-type", "application/fuzzmangle" )
                |> Debug.log "conn"
                |> send responsePort



-- SUBSCRIPTIONS


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg


subscriptions : Conn -> Sub Msg
subscriptions _ =
    Sub.none
