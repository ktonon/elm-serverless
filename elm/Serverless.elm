module Serverless
    exposing
        ( httpApi
        , HttpApi
        , EndpointPort
        , Stage
        )

{-| Define an HTTP API in elm.

@docs httpApi, HttpApi, EndpointPort, Stage
-}

import Serverless.Request as Request exposing (..)
import Serverless.Response as Response exposing (..)


{-| Create an HttpApi.

This program guarantees a decoded Request for your init function. If an error
happens during decoding, it will send 500 through the responsePort that
you provide and never call init.
-}
httpApi : HttpApi model msg -> Platform.Program Request.Raw (Maybe model) msg
httpApi program =
    Platform.programWithFlags
        { init = maybeInit program
        , update = maybeUpdate program
        , subscriptions = maybeSub program
        }


{-| Program for an HTTP API.

Differs from Platform.program as follows

* endpointPort - port through which the HTTP request begins
* responsePort - port through which the HTTP request ends
* init - guaranteed to get a decoded Request
-}
type alias HttpApi model msg =
    { endpointPort : EndpointPort msg
    , responsePort : Response.Port msg
    , init : Request -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    }


{-| A port through which the HTTP request begins.

It receives the serverless stage as an parameter.
-}
type alias EndpointPort msg =
    (Stage -> msg) -> Sub msg


{-| A serverless stage (ex, "dev")
-}
type alias Stage =
    String



-- IMPLEMENTATION


maybeInit : HttpApi model msg -> Request.Raw -> ( Maybe model, Cmd msg )
maybeInit program raw =
    case Request.decode raw of
        Ok req ->
            let
                ( model, cmd ) =
                    program.init req
            in
                ( Just model, Cmd.none )

        Err err ->
            ( Nothing, program.responsePort ( 500, err ) )


maybeUpdate : HttpApi model msg -> msg -> Maybe model -> ( Maybe model, Cmd msg )
maybeUpdate program msg maybeModel =
    case maybeModel of
        Just model ->
            let
                ( newModel, cmd ) =
                    program.update msg model
            in
                ( Just newModel, cmd )

        Nothing ->
            ( Nothing, program.responsePort ( 500, "Failed to initialize" ) )


maybeSub : HttpApi model msg -> Maybe model -> Sub msg
maybeSub program maybeModel =
    case maybeModel of
        Just model ->
            program.subscriptions model

        Nothing ->
            Sub.none
