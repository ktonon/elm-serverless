module Serverless
    exposing
        ( Flags
        , HttpApi
        , Interop
        , Program
        , httpApi
        , noConfig
        , noInterop
        , noRoutes
        , noSideEffects
        )

{-| Use `httpApi` to define a `Program` that responds to HTTP requests. Take a look
at the [demo](https://github.com/ktonon/elm-serverless/blob/master/demo/src/API.elm)
for a usage example.

@docs Program, Flags, httpApi, HttpApi


## JavaScript Interop

@docs Interop


## Initialization Helpers

Various aspects of Program may not be needed. These functions are provided as a
convenient way to opt-out.

@docs noConfig, noInterop, noRoutes, noSideEffects

-}

import Json.Decode exposing (Decoder, decodeValue)
import Json.Encode
import Serverless.Conn as Conn exposing (Conn, Id)
import Serverless.Conn.Body as Body
import Serverless.Conn.Pool as ConnPool
import Serverless.Conn.Request as Request
import Serverless.Conn.Response as Response exposing (Status)
import Serverless.Port as Port


{-| Serverless program type.

This maps to a headless elm
[Platform.Program](http://package.elm-lang.org/packages/elm-lang/core/latest/Platform#Program).

-}
type alias Program config model route interop msg =
    Platform.Program Flags (Model config model route interop) (RawMsg msg)


{-| Type of flags for program.

`Value` is a
[Json.Encode.Value](http://package.elm-lang.org/packages/elm-lang/core/latest/Json-Encode#Value).
The program configuration (`config`) is passed in as flags.

-}
type alias Flags =
    Json.Encode.Value


{-| Create a program from the given HTTP api.
-}
httpApi :
    HttpApi config model route interop msg
    -> Program config model route interop msg
httpApi api =
    Platform.programWithFlags
        { init = init_ api
        , update = update_ api
        , subscriptions = sub_ api
        }


{-| Program for an HTTP API.

A Serverless.Program is parameterized by your 4 custom types

  - `config` is a server load-time record of deployment specific values
  - `model` is for whatever you need during the processing of a request
  - `route` represents your application routes
  - `msg` is your app message type

You must provide the following:

  - `configDecoder` decodes a JSON value for your custom config type
  - `requestPort` and `responsePort` must be defined in your app since an elm library cannot expose ports
  - `endpoint` is a message through which connections are first received
  - `initialModel` is a value to which new connections will set their model
  - `parseRoute` takes the `request/path/and?query=string` and parses it into a `route`
  - `update` the app update function
  - `subscriptions` the app subscriptions function

Notices that `update` and `subscriptions` operate on `Conn config model route interop`
and not just on `model`.

-}
type alias HttpApi config model route interop msg =
    { configDecoder : Decoder config
    , initialModel : model
    , parseRoute : String -> Maybe route
    , endpoint : Conn config model route interop -> ( Conn config model route interop, Cmd msg )
    , update : msg -> Conn config model route interop -> ( Conn config model route interop, Cmd msg )
    , interop : Interop interop msg
    , requestPort : Port.Request (RawMsg msg)
    , responsePort : Port.Response (RawMsg msg)
    }


{-| Translates Elm data to and from JSON.
-}
type alias Interop interop msg =
    { encodeInput : interop -> Json.Encode.Value
    , outputDecoder : String -> Maybe (Json.Decode.Decoder msg)
    }



-- OPT-OUT PROGRAM INITIALIZERS


{-| Opt-out of configuration decoding.
-}
noConfig : Json.Decode.Decoder ()
noConfig =
    Json.Decode.succeed ()


{-| Opt-out of JavaScript interop.
-}
noInterop : Interop () msg
noInterop =
    Interop (\() -> Json.Encode.null) (\_ -> Nothing)


{-| Opt-out of route parsing.
-}
noRoutes : String -> Maybe ()
noRoutes _ =
    Just ()


{-| Opt-out of side-effects.
-}
noSideEffects :
    ()
    -> Conn config model route interop
    -> ( Conn config model route interop, Cmd () )
noSideEffects _ conn =
    ( conn, Cmd.none )



-- IMPLEMENTATION


type alias Model config model route interop =
    { pool : ConnPool.Pool config model route interop
    , config : config
    }


type RawMsg msg
    = RequestPort Port.IO
    | HandlerMsg Id msg


type SlsMsg config model route interop msg
    = RequestAdd (Conn config model route interop)
    | RequestUpdate Id msg
    | ProcessingError Id Int String


init_ :
    HttpApi config model route interop msg
    -> Flags
    -> ( Model config model route interop, Cmd (RawMsg msg) )
init_ api flags =
    case decodeValue api.configDecoder flags of
        Ok config ->
            ( { pool = ConnPool.empty
              , config = config
              }
                |> Debug.log "Initialized"
            , Cmd.none
            )

        Err err ->
            Debug.crash "Initialization failed" err


toSlsMsg :
    HttpApi config model route interop msg
    -> config
    -> RawMsg msg
    -> SlsMsg config model route interop msg
toSlsMsg api config rawMsg =
    case rawMsg of
        RequestPort ( id, action, raw ) ->
            case action of
                "__request__" ->
                    case decodeValue Request.decoder raw of
                        Ok req ->
                            case
                                api.parseRoute <|
                                    (Request.path req ++ Request.queryString req)
                            of
                                Just route ->
                                    RequestAdd <| Conn.init id config api.initialModel route req

                                Nothing ->
                                    ProcessingError id 404 <|
                                        (++) "Could not parse route: "
                                            (Request.path req)

                        Err err ->
                            ProcessingError id 500 <|
                                (++) "Misconfigured server. Make sure the elm-serverless npm package version matches the elm package version."
                                    (toString err)

                action ->
                    case decodeOutput api.interop action raw of
                        Ok msg ->
                            RequestUpdate id msg

                        Err err ->
                            ProcessingError id 500 <|
                                (++) "Error decoding interop result: " err

        HandlerMsg id msg ->
            RequestUpdate id msg


update_ :
    HttpApi config model route interop msg
    -> RawMsg msg
    -> Model config model route interop
    -> ( Model config model route interop, Cmd (RawMsg msg) )
update_ api rawMsg model =
    case toSlsMsg api model.config rawMsg of
        RequestAdd conn ->
            updateChildHelper api
                (api.endpoint conn)
                model

        RequestUpdate connId msg ->
            updateChild api connId msg model

        ProcessingError connId status err ->
            ( model, send api connId status err )


updateChild :
    HttpApi config model route interop msg
    -> Id
    -> msg
    -> Model config model route interop
    -> ( Model config model route interop, Cmd (RawMsg msg) )
updateChild api connId msg model =
    case ConnPool.get connId model.pool of
        Just conn ->
            updateChildHelper api (api.update msg conn) model

        _ ->
            ( model
            , send api connId 500 <|
                (++) "No connection in pool with id: " connId
            )


updateChildHelper :
    HttpApi config model route interop msg
    -> ( Conn config model route interop, Cmd msg )
    -> Model config model route interop
    -> ( Model config model route interop, Cmd (RawMsg msg) )
updateChildHelper api ( conn, cmd ) model =
    case Conn.unsent conn of
        Nothing ->
            ( { model | pool = model.pool |> ConnPool.remove conn }
            , api.responsePort
                ( Conn.id conn
                , "__response__"
                , Conn.jsonEncodedResponse conn
                )
            )

        Just conn ->
            ( { model
                | pool =
                    ConnPool.replace
                        (Conn.interopClear conn)
                        model.pool
              }
            , Cmd.batch
                [ Cmd.map (HandlerMsg (Conn.id conn)) cmd
                , interopCallCmd api conn
                ]
            )


sub_ :
    HttpApi config model route interop msg
    -> Model config model route interop
    -> Sub (RawMsg msg)
sub_ api model =
    api.requestPort RequestPort



-- HELPERS


send :
    HttpApi config model route interop msg
    -> Id
    -> Status
    -> String
    -> Cmd (RawMsg msg)
send { responsePort } id code msg =
    responsePort
        ( id
        , "__response__"
        , Response.init
            |> Response.setStatus code
            |> Response.setBody (Body.text msg)
            |> Response.encode
        )



-- JAVASCRIPT INTEROP


interopCallCmd :
    HttpApi config model route interop msg
    -> Conn config model route interop
    -> Cmd (RawMsg msg)
interopCallCmd api conn =
    conn
        |> Conn.interopCalls
        |> List.map
            (\interop ->
                api.responsePort
                    ( Conn.id conn
                    , interopFunctionName interop
                    , encodeInput api.interop interop
                    )
            )
        |> Cmd.batch


interopFunctionName : interop -> String
interopFunctionName interop =
    let
        name =
            interop |> toString |> String.split " " |> List.head |> Maybe.withDefault ""
    in
    (++)
        (name |> String.left 1 |> String.toLower)
        (name |> String.dropLeft 1)


encodeInput :
    Interop interop msg
    -> interop
    -> Json.Encode.Value
encodeInput { encodeInput } interop =
    encodeInput interop


decodeOutput :
    Interop interop msg
    -> String
    -> Json.Encode.Value
    -> Result String msg
decodeOutput { outputDecoder } interopName jsonValue =
    case outputDecoder interopName of
        Just decoder ->
            Json.Decode.decodeValue decoder jsonValue

        Nothing ->
            Err <|
                "Could not get decoder for interop named: "
                    ++ interopName
