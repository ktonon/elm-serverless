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

__Experimental (WIP): Not for use in production__

@docs httpApi, Flags, HttpApi, Program, RequestPort, ResponsePort
-}

import Json.Decode exposing (Decoder, decodeValue)
import Json.Encode as J
import Serverless.Conn as Conn exposing (..)
import Serverless.Conn.Pool as Pool exposing (..)
import Serverless.Conn.PrivateRequest exposing (..)
import Serverless.Conn.Request exposing (Id)


{-| Create an program for handling HTTP connections.
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

A Serverless.Program is parameterized by your 3 custom types

* Config is a server load-time record of deployment specific values
* Model is for whatever you need during the processing of a request
* Msg is your app message type

You must provide the following:

* `configDecoder` decodes a JSON value for your custom config type
* `requestPort` and `responsePort` must be defined in your app since an elm library cannot expose ports. They should have types `Serverless.RequestPort` and `Serverless.ResponsePort`, respectively
* `endpoint` is a message through which connections are first received
* `initialModel` is a value to which new connections will set their model
* `update` and `subscriptions` have the usual meaning, but operate on individual connections
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


{-| Type of port through which the request is received.
Set your request port to this type.
-}
type alias RequestPort msg =
    (J.Value -> msg) -> Sub msg


{-| Type of port through which the request is sent.
Set your response port to this type.
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
