module Serverless.Conn exposing (..)

{-| Functions for transforming a connection.

## Table of Contents

* [Response](#response)
* [Responding with Errors](#responding-with-errors)
* [Pipeline Processing](#pipeline-processing)
* [Application Specific](#application-specific)

Most of these functions can be curried and used directly as simple plugs. For
example

    pipeline
        |> plug (header ( "access-control-allow-origin", "*" ))

Or they can be used inside of a plug as part of a chain of connection
transformations. For example,

    conn
        |> status (Code 200)
        |> header ( "content-type", "text/text" )
        |> body (TextBody "hello world")

## Response

The following functions are used to transform and send the HTTP response.

@docs body, header, status, send

## Responding with Errors

The following functions set the HTTP status code to 500 and send a response
with an error message.

@docs internalError, unexpectedMsg

## Pipeline Processing

The following functions can be used inside of a loop plug which needs to wait for
the results of a side effect.

@docs pipelinePause, pipelineResume

## Application Specific

@docs updateModel
-}

import Json.Encode as J
import Serverless.Conn.Types exposing (..)
import Serverless.Conn.Private exposing (..)


-- CONTROL FLOW


{-| Pause the connection at the current loop plug.

Increments the pause count by the amount given. You will need to resume by the
same amount for pipeline processing to continue onto the next plug.

    conn
        |> pause 1
            ("http://example.com"
                |> Http.getString
                |> Http.send HandleResult
            )
            responsePort

An internal server error will be sent through the responsePort if the pause
increment is not positive.
-}
pipelinePause : Int -> Cmd msg -> (J.Value -> Cmd msg) -> Conn config model -> ( Conn config model, Cmd msg )
pipelinePause i cmd port_ conn =
    if i < 1 then
        conn |> internalError "pause pipeline called with non-positive value" port_
    else
        ( case conn.pipelineState of
            Processing ->
                { conn | pipelineState = Paused i }

            Paused j ->
                { conn | pipelineState = Paused (i + j) }
        , cmd
        )


{-| Resume pipeline processing.

Decrements the pause count by the amount given. You should only call this after
a call to pause, and should decrement it by the same amount. It is ok to make
multiple calls, as long as the sum of pauses equals the sum of resumes.

    case msg of
        HandleResult result ->
            case result of
                Ok value ->
                    conn |> resume 1 responsePort

                Err err ->
                    conn |> internalError "did not work" responsePort

An internal server error will be sent through the responsePort if the pause
count goes below zero.
-}
pipelineResume : Int -> (J.Value -> Cmd msg) -> Conn config model -> ( Conn config model, Cmd msg )
pipelineResume i port_ conn =
    if i < 1 then
        conn |> internalError "resume pipeline called with non-positive value" port_
    else
        case conn.pipelineState of
            Processing ->
                conn |> internalError "resume pipeline called, but processing was not paused" port_

            Paused j ->
                if j - i > 0 then
                    ( { conn | pipelineState = Paused (j - i) }, Cmd.none )
                else if j - i == 0 then
                    ( { conn | pipelineState = Processing }, Cmd.none )
                else
                    conn |> internalError "resume pipeline underflow" port_



-- MODEL


{-| Transform and update the application defined model stored in the connection.
-}
updateModel : (model -> model) -> Conn config model -> Conn config model
updateModel update conn =
    { conn | model = update conn.model }



-- REQUEST
-- RESPONSE


{-| Set the response body
-}
body : Body -> Conn config model -> Conn config model
body val conn =
    case conn.resp of
        Unsent resp ->
            { conn | resp = Unsent { resp | body = val } }

        Sent ->
            conn


{-| Set a response header
-}
header : ( String, String ) -> Conn config model -> Conn config model
header ( key, value ) conn =
    case conn.resp of
        Unsent resp ->
            { conn
                | resp =
                    Unsent
                        { resp
                            | headers =
                                ( key |> String.toLower, value )
                                    :: resp.headers
                        }
            }

        Sent ->
            conn


{-| Set the response HTTP status code
-}
status : Status -> Conn config model -> Conn config model
status val conn =
    case conn.resp of
        Unsent resp ->
            { conn | resp = Unsent { resp | status = val } }

        Sent ->
            conn


{-| Sends a connection response through the given port
-}
send : (J.Value -> Cmd msg) -> Conn config model -> ( Conn config model, Cmd msg )
send port_ conn =
    case conn.resp of
        Unsent resp ->
            ( { conn | resp = Sent }
            , resp |> encodeResponse conn.req.id |> port_
            )

        Sent ->
            ( conn
            , Cmd.none
            )



-- ERRORS


{-| Respond with a 500 internal server error.

The given value is converted to a string and set to the response body.
-}
internalError : a -> (J.Value -> Cmd msg) -> Conn config model -> ( Conn config model, Cmd msg )
internalError val port_ conn =
    conn
        |> status (Code 500)
        |> header ( "content-type", "text/text" )
        |> body (val |> toString |> TextBody)
        |> send port_


{-| Respond with an unexpected message error.

Use this in the `case msg of` catch-all (`_ ->`) for any messages that you do
not respect to receive in a loop plug.
-}
unexpectedMsg : msg -> (J.Value -> Cmd msg) -> Conn config model -> ( Conn config model, Cmd msg )
unexpectedMsg msg =
    internalError ("unexpected msg: " ++ (msg |> toString))
