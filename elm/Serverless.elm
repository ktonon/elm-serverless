port module Serverless
    exposing
        ( httpApi
        , endpoint
        , Program
        , Stage
        )

import Serverless.Request as Request exposing (..)
import Serverless.Response as Response exposing (..)


httpApi : Program model msg -> Platform.Program Request.Raw (Maybe model) msg
httpApi program =
    Platform.programWithFlags
        { init = maybeInit program
        , update = maybeUpdate program
        , subscriptions = maybeSub program
        }


port endpoint : (Stage -> msg) -> Sub msg


type alias Program model msg =
    { endpoint : Stage -> msg
    , init : Request -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    }


type alias Stage =
    String



-- IMPLEMENTATION


maybeInit : Program model msg -> Request.Raw -> ( Maybe model, Cmd msg )
maybeInit program raw =
    case Request.decode raw of
        Ok req ->
            let
                ( model, cmd ) =
                    program.init req
            in
                ( Just model, Cmd.none )

        Err err ->
            ( Nothing, response ( 500, err ) )


maybeUpdate : Program model msg -> msg -> Maybe model -> ( Maybe model, Cmd msg )
maybeUpdate program msg maybeModel =
    case maybeModel of
        Just model ->
            let
                ( newModel, cmd ) =
                    program.update msg model
            in
                ( Just newModel, cmd )

        Nothing ->
            ( Nothing, response ( 500, "Failed to initialize" ) )


maybeSub : Program model msg -> Maybe model -> Sub msg
maybeSub program maybeModel =
    case maybeModel of
        Just model ->
            Sub.batch
                [ endpoint program.endpoint
                , program.subscriptions model
                ]

        Nothing ->
            Sub.none
