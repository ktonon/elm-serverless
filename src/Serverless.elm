module Serverless
    exposing
        ( Flags
        , HttpApi
        , Program
        , httpApi
        )

{-| Use `httpApi` to define a `Program` that responds to HTTP requests. Take a look
at the [demo](https://github.com/ktonon/elm-serverless/blob/master/demo/src/API.elm)
for a usage example.

@docs Program, Flags, httpApi, HttpApi

-}

import Json.Decode exposing (Decoder, decodeValue)
import Json.Encode
import Logging exposing (defaultLogger)
import Serverless.Conn as Conn exposing (Conn)
import Serverless.Conn.Body as Body
import Serverless.Conn.Pool as ConnPool
import Serverless.Conn.Request as Request exposing (Id)
import Serverless.Conn.Response as Response exposing (Status)
import Serverless.Port as Port


{-| Serverless program type.

This maps to a headless elm
[Platform.Program](http://package.elm-lang.org/packages/elm-lang/core/latest/Platform#Program).

-}
type alias Program config model route msg =
    Platform.Program Flags (Model config model route) (Msg msg)


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
    HttpApi config model route msg
    -> Program config model route msg
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

Notices that `update` and `subscriptions` operate on `Conn config model route`
and not just on `model`.

-}
type alias HttpApi config model route msg =
    { configDecoder : Decoder config
    , requestPort : Port.Request (Msg msg)
    , responsePort : Port.Response (Msg msg)
    , endpoint : msg
    , initialModel : model
    , parseRoute : String -> Maybe route
    , update : msg -> Conn config model route -> ( Conn config model route, Cmd msg )
    , subscriptions : Conn config model route -> Sub msg
    }



-- IMPLEMENTATION


type alias Model config model route =
    { pool : ConnPool.Pool config model route
    }


type Msg msg
    = RawRequest Json.Encode.Value
    | HandlerMsg Id msg


init_ :
    HttpApi config model route msg
    -> Flags
    -> ( Model config model route, Cmd (Msg msg) )
init_ api flags =
    case decodeValue api.configDecoder flags of
        Ok config ->
            ( ConnPool.empty api.initialModel (Just config)
                |> Model
                |> Debug.log "Initialized"
            , Cmd.none
            )

        Err err ->
            ConnPool.empty api.initialModel Nothing
                |> Model
                |> reportFailure "Initialization failed" err


update_ :
    HttpApi config model route msg
    -> Msg msg
    -> Model config model route
    -> ( Model config model route, Cmd (Msg msg) )
update_ api slsMsg model =
    case slsMsg of
        RawRequest raw ->
            case decodeValue Request.decoder raw of
                Ok req ->
                    case
                        api.parseRoute <|
                            (Request.path req ++ Request.queryString req)
                    of
                        Just route ->
                            { model | pool = ConnPool.add defaultLogger route req model.pool }
                                |> updateChild api
                                    (Request.id req)
                                    api.endpoint

                        Nothing ->
                            ( model
                            , send api (Request.id req) 404 <|
                                (++) "Could not parse route: " <|
                                    Request.path req
                            )

                Err err ->
                    reportFailure
                        "Misconfigured server. Make sure the elm-serverless npm package version matches the elm package version."
                        err
                        model

        HandlerMsg connId msg ->
            updateChild api connId msg model


updateChild : HttpApi config model route msg -> Id -> msg -> Model config model route -> ( Model config model route, Cmd (Msg msg) )
updateChild api connId msg model =
    case ConnPool.get connId model.pool of
        Just conn ->
            let
                ( newConn, cmd ) =
                    api.update msg conn
            in
            case Conn.unsent newConn of
                Nothing ->
                    ( { model | pool = model.pool |> ConnPool.remove connId }
                    , api.responsePort (Conn.jsonEncodedResponse newConn)
                    )

                Just newConn ->
                    ( { model | pool = model.pool |> ConnPool.replace newConn }
                    , Cmd.map (HandlerMsg connId) cmd
                    )

        _ ->
            ( model
            , send api connId 500 <|
                (++) "No connection in pool with id: " connId
            )


sub_ :
    HttpApi config model route msg
    -> Model config model route
    -> Sub (Msg msg)
sub_ api model =
    model.pool
        |> ConnPool.connections
        |> List.map (connSub api)
        |> List.append [ api.requestPort RawRequest ]
        |> Sub.batch


connSub : HttpApi config model route msg -> Conn config model route -> Sub (Msg msg)
connSub api conn =
    api.subscriptions conn
        |> Sub.map (HandlerMsg (Conn.id conn))



-- HELPERS


reportFailure : String -> value -> Model config model route -> ( Model config model route, Cmd (Msg msg) )
reportFailure msg value model =
    let
        _ =
            Debug.log msg value
    in
    ( model, Cmd.none )


send :
    HttpApi config model route msg
    -> Id
    -> Status
    -> String
    -> Cmd (Msg msg)
send { responsePort } id code msg =
    Response.init
        |> Response.setStatus code
        |> Response.setBody (Body.text msg)
        |> Response.encode id
        |> responsePort
