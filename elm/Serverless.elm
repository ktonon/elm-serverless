module Serverless
    exposing
        ( httpApi
        , Flags
        , HttpApi
        , Program
        , RequestPort
        , ResponsePort
        )

{-| Define an HTTP API in elm.

@docs httpApi, Flags, HttpApi, Program, RequestPort, ResponsePort
-}

import Json.Decode exposing (Decoder, decodeValue)
import Json.Encode as J
import Serverless.Conn as Conn exposing (..)
import Serverless.Conn.Pool as Pool exposing (..)
import Serverless.Conn.PrivateRequest exposing (..)
import Serverless.Conn.Request exposing (Id)


{-| Create an HttpApi.

This program guarantees a decoded Request for your init function. If an error
happens during decoding, it will send 500 through the responsePort that
you provide and never call init.
-}
httpApi :
    HttpApi config model msg
    -> Program config model msg
httpApi program =
    Platform.programWithFlags
        { init = init_ program
        , update = update_ program
        , subscriptions = sub_ program
        }


{-| Serverless program type
-}
type alias Program config model msg =
    Platform.Program Flags (Pool config model) (Msg msg)


{-| Type of flags for program
-}
type alias Flags =
    J.Value


{-| Program for an HTTP API.

Differs from Platform.program as follows

* endpointPort - port through which the HTTP request begins
* responsePort - port through which the HTTP request ends
* init - guaranteed to get a decoded Request
-}
type alias HttpApi config model msg =
    { configDecoder : Decoder config
    , requestPort : RequestPort (Msg msg)
    , responsePort : ResponsePort (Msg msg)
    , endpoint : msg
    , initialModel : model
    , update : msg -> Conn config model -> ( Conn config model, Cmd msg )
    , subscriptions : Conn config model -> Sub msg
    }


{-| A port through which the request is received
-}
type alias RequestPort msg =
    (J.Value -> msg) -> Sub msg


{-| A port through which the request is sent
-}
type alias ResponsePort msg =
    J.Value -> Cmd msg



-- IMPLEMENTATION


init_ :
    HttpApi config model msg
    -> Flags
    -> ( Pool config model, Cmd (Msg msg) )
init_ program flags =
    case decodeValue program.configDecoder flags of
        Ok config ->
            ( Debug.log "Initialized" (Pool.empty program.initialModel (Just config))
            , Cmd.none
            )

        Err err ->
            Pool.empty program.initialModel Nothing
                |> reportFailure "Initialization failed" err


type Msg msg
    = RawRequest J.Value
    | HandlerMsg Id msg


update_ :
    HttpApi config model msg
    -> Msg msg
    -> Pool config model
    -> ( Pool config model, Cmd (Msg msg) )
update_ program slsMsg pool =
    case slsMsg of
        RawRequest raw ->
            case raw |> decodeValue requestDecoder of
                Ok req ->
                    pool
                        |> Pool.add req
                        |> updateChild program req.id program.endpoint

                Err err ->
                    pool |> reportFailure "Error decoding request" err

        HandlerMsg requestId msg ->
            updateChild program requestId msg pool


updateChild : HttpApi config model msg -> Id -> msg -> Pool config model -> ( Pool config model, Cmd (Msg msg) )
updateChild program requestId msg pool =
    case pool |> Pool.get requestId of
        Just conn ->
            let
                ( newConn, cmd ) =
                    program.update msg conn
            in
                ( pool |> Pool.replace newConn
                , Cmd.map (HandlerMsg requestId) cmd
                )

        _ ->
            pool |> reportFailure "No connection in pool with id: " requestId


sub_ :
    HttpApi config model msg
    -> Pool config model
    -> Sub (Msg msg)
sub_ program pool =
    pool
        |> Pool.connections
        |> List.map
            (\conn ->
                Sub.map
                    (HandlerMsg conn.req.id)
                    (program.subscriptions conn)
            )
        |> List.append [ program.requestPort RawRequest ]
        |> Sub.batch


reportFailure : String -> value -> Pool config model -> ( Pool config model, Cmd msg )
reportFailure msg value pool =
    let
        _ =
            Debug.log msg value
    in
        ( pool, Cmd.none )
