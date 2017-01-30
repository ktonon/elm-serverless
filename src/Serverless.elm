module Serverless
    exposing
        ( cors
        , httpApi
        , Flags
        , HttpApi
        , Program
        )

{-| __Experimental (WIP): Not for use in production__

## Table of Contents

* [Defining a Program](#defining-a-program)
* [Built-in Middleware](#built-in-middleware)

## Defining a Program

Use `httpApi` to define a `Program` that responds to HTTP requests. Take a look
at the [demo](https://github.com/ktonon/elm-serverless/blob/master/demo/src/API.elm)
for a usage example. Then read about [Building Pipelines](./Conn#building-pipelines)
to get an idea of how an `elm-serverless Program` works.

@docs Program, Flags, httpApi, HttpApi

## Built-in Middleware

The following middleware comes built-in. Insert these functions into your
pipelines to easily add functionality. See
[Building Pipelines](./Conn#building-pipelines) for more details.

@docs cors
-}

import Json.Decode exposing (Decoder, decodeValue)
import Json.Encode as J
import Logging exposing (defaultLogger)
import Serverless.Conn as Conn
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


{-| Type of flags for program.

`Value` is a
[Json.Encode.Value](http://package.elm-lang.org/packages/elm-lang/core/latest/Json-Encode#Value).
The program configuration (`config`) is passed in as flags.
-}
type alias Flags =
    J.Value


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

See the Plug module for more details on pipelines and plugs.
-}
type alias HttpApi config model msg =
    { configDecoder : Decoder config
    , requestPort : RequestPort (Msg msg)
    , responsePort : ResponsePort (Msg msg)
    , endpoint : msg
    , initialModel : model
    , pipeline : Pipeline config model msg
    , subscriptions : Conn config model -> Sub msg
    }



-- MIDDLEWARE


{-| Add cors headers to the response.

    pipeline
        |> plug (cors "*" [ GET, OPTIONS ])
-}
cors : String -> List Method -> Conn config model -> Conn config model
cors origin methods =
    (Conn.header ( "access-control-allow-origin", origin ))
        >> (Conn.header
                ( "access-control-allow-headers"
                , methods
                    |> List.map toString
                    |> String.join ", "
                )
           )



-- IMPLEMENTATION


type alias Model config model =
    { pool : Pool config model
    }


init_ :
    HttpApi config model msg
    -> Flags
    -> ( Model config model, Cmd (Msg msg) )
init_ program flags =
    case decodeValue program.configDecoder flags of
        Ok config ->
            ( emptyPool program.initialModel (Just config)
                |> Model
                |> Debug.log "Initialized"
            , Cmd.none
            )

        Err err ->
            emptyPool program.initialModel Nothing
                |> Model
                |> reportFailure "Initialization failed" err


update_ :
    HttpApi config model msg
    -> Msg msg
    -> Model config model
    -> ( Model config model, Cmd (Msg msg) )
update_ program slsMsg model =
    case slsMsg of
        RawRequest raw ->
            case raw |> decodeValue requestDecoder of
                Ok req ->
                    { model | pool = model.pool |> addToPool defaultLogger req }
                        |> updateChild program
                            req.id
                            (PlugMsg firstIndexPath program.endpoint)

                Err err ->
                    model |> reportFailure "Error decoding request" err

        HandlerMsg requestId msg ->
            updateChild program requestId msg model


updateChild : HttpApi config model msg -> Id -> PlugMsg msg -> Model config model -> ( Model config model, Cmd (Msg msg) )
updateChild program requestId msg model =
    case model.pool |> getFromPool requestId of
        Just conn ->
            let
                ( newConn, cmd ) =
                    applyPipeline
                        (Options program.endpoint
                            program.responsePort
                            program.pipeline
                        )
                        msg
                        0
                        []
                        conn
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
sub_ program model =
    model.pool
        |> poolConnections
        |> List.map (connSub program)
        |> List.append [ program.requestPort RawRequest ]
        |> Sub.batch


connSub : HttpApi config model msg -> Conn config model -> Sub (Msg msg)
connSub program conn =
    program.subscriptions conn
        |> Sub.map (PlugMsg firstIndexPath)
        |> Sub.map (HandlerMsg conn.req.id)


reportFailure : String -> value -> Model config model -> ( Model config model, Cmd (Msg msg) )
reportFailure msg value model =
    let
        _ =
            Debug.log msg value
    in
        ( model, Cmd.none )
