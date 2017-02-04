module Serverless
    exposing
        ( httpApi
        , Flags
        , HttpApi
        , Program
        )

{-| Use `httpApi` to define a `Program` that responds to HTTP requests. Take a look
at the [demo](https://github.com/ktonon/elm-serverless/blob/master/demo/src/API.elm)
for a usage example. Then read about [Building Pipelines](./Serverless-Conn#building-pipelines).

@docs Program, Flags, httpApi, HttpApi

-}

import Json.Decode exposing (Decoder, decodeValue)
import Json.Encode as J
import Logging exposing (defaultLogger)
import Serverless.Pool exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Pipeline exposing (..)
import Serverless.Types exposing (..)


{-| Serverless program type.

This maps to a headless elm
[Platform.Program](http://package.elm-lang.org/packages/elm-lang/core/latest/Platform#Program).
-}
type alias Program config model msg =
    Platform.Program Flags (Model config model) (Msg msg)


toPipelineOptions :
    HttpApi config model msg
    -> Serverless.Pipeline.Options config model msg
toPipelineOptions api =
    Serverless.Pipeline.newOptions api.endpoint
        api.responsePort
        api.pipeline


{-| Type of flags for program.

`Value` is a
[Json.Encode.Value](http://package.elm-lang.org/packages/elm-lang/core/latest/Json-Encode#Value).
The program configuration (`config`) is passed in as flags.
-}
type alias Flags =
    J.Value


{-| Create a program from the given HTTP api.
-}
httpApi :
    HttpApi config model msg
    -> Program config model msg
httpApi api =
    Platform.programWithFlags
        { init = init_ api
        , update = update_ api
        , subscriptions = sub_ api
        }


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
* `pipeline` takes the place of the update function in a traditional elm program
* `subscriptions` has the usual meaning

See [Building Pipelines](./Serverless-Conn#building-pipelines) for more details on
the `pipeline` parameter.
-}
type alias HttpApi config model msg =
    { configDecoder : Decoder config
    , requestPort : RequestPort (Msg msg)
    , responsePort : ResponsePort (Msg msg)
    , endpoint : msg
    , initialModel : model
    , pipeline : Plug config model msg
    , subscriptions : Conn config model -> Sub msg
    }



-- IMPLEMENTATION


type alias Model config model =
    { pool : Pool config model
    }


init_ :
    HttpApi config model msg
    -> Flags
    -> ( Model config model, Cmd (Msg msg) )
init_ api flags =
    case decodeValue api.configDecoder flags of
        Ok config ->
            ( emptyPool api.initialModel (Just config)
                |> Model
                |> Debug.log "Initialized"
            , Cmd.none
            )

        Err err ->
            emptyPool api.initialModel Nothing
                |> Model
                |> reportFailure "Initialization failed" err


update_ :
    HttpApi config model msg
    -> Msg msg
    -> Model config model
    -> ( Model config model, Cmd (Msg msg) )
update_ api slsMsg model =
    case slsMsg of
        RawRequest raw ->
            case raw |> decodeValue requestDecoder of
                Ok req ->
                    { model | pool = model.pool |> addToPool defaultLogger req }
                        |> updateChild api
                            req.id
                            (PlugMsg firstIndexPath api.endpoint)

                Err err ->
                    model |> reportFailure "Error decoding request" err

        HandlerMsg requestId msg ->
            updateChild api requestId msg model


updateChild : HttpApi config model msg -> Id -> PlugMsg msg -> Model config model -> ( Model config model, Cmd (Msg msg) )
updateChild api requestId msg model =
    case model.pool |> getFromPool requestId of
        Just conn ->
            let
                ( newConn, cmd ) =
                    conn |> applyPipeline (api |> toPipelineOptions) msg
            in
                ( { model | pool = model.pool |> replaceInPool newConn }
                , cmd
                )

        _ ->
            model |> reportFailure "No connection in pool with id: " requestId


sub_ :
    HttpApi config model msg
    -> Model config model
    -> Sub (Msg msg)
sub_ api model =
    model.pool
        |> poolConnections
        |> List.map (connSub api)
        |> List.append [ api.requestPort RawRequest ]
        |> Sub.batch


connSub : HttpApi config model msg -> Conn config model -> Sub (Msg msg)
connSub api conn =
    api.subscriptions conn
        |> Sub.map (PlugMsg firstIndexPath)
        |> Sub.map (HandlerMsg conn.req.id)


reportFailure : String -> value -> Model config model -> ( Model config model, Cmd (Msg msg) )
reportFailure msg value model =
    let
        _ =
            Debug.log msg value
    in
        ( model, Cmd.none )
