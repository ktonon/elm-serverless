module Serverless.Conn exposing (..)

{-| Functions for building pipelines and processing connections.

## Terminology

`Conn` stands for __connection__. A connection contains:

* An HTTP request
* An HTTP response, unsent, and waiting for you to provide meaningful values
* Your custom deployment configuration data
* Your custom appliation `Model`

A __pipeline__ is a sequence of functions which transform the connection,
eventually sending back the HTTP response. We use the term __plug__ to mean a
single function that is part of the pipeline. But a pipeline is also just a plug
and so pipelines can be composed from other pipelines.

## Table of Contents

* [Building Pipelines](#building-pipelines)
* [Routing](#routing)
* [Response](#response)
* [Responding with Errors](#responding-with-errors)
* [Pipeline Processing](#pipeline-processing)
* [Application Specific](#application-specific)

## Building Pipelines

Use these functions to build your pipelines. For example,

    myPipeline =
        pipeline
            |> plug simplePlugA
            |> plug simplePlugB
            |> loop loadSomeDatabaseStuff
            |> nest anotherPipeline
            |> fork router

@docs pipeline, plug, loop, fork, nest

## Routing

@docs parseRoute

## Response

The following functions are used to transform and send the HTTP response. Most
of these functions can be curried and used directly as simple plugs. For
example

    pipeline
        |> plug (header ( "access-control-allow-origin", "*" ))

Or they can be used inside of a plug as part of a chain of connection
transformations. For example,

    conn
        |> status (Code 200)
        |> header ( "content-type", "text/text" )
        |> body (TextBody "hello world")

@docs body, textBody, jsonBody, header, status, statusCode, send, toResponder

## Responding with Errors

The following functions set the HTTP status code to 500 and set the body to
an error response.

@docs internalError, unexpectedMsg

## Pipeline Processing

The following functions can be used inside of a loop plug which needs to wait for
the results of a side effect.

@docs pipelinePause, pipelineResume

## Application Specific

@docs updateModel
-}

import Array
import Dict
import Json.Encode as J
import Serverless.Pool exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Types exposing (..)
import UrlParser exposing (Parser, (</>), oneOf, parse, map, int, s)


-- BUILDING PIPELINES


{-| Begins a pipeline.

Build the pipeline by chaining plugs with plug, loop, fork, and nest.
-}
pipeline : Plug config model msg
pipeline =
    Pipeline Array.empty


{-| Extends the pipeline with a plug.

This is the most general of the pipeline building functions. Since it just
accepts a plug, and since a plug can be a pipeline, it can be used to extend a
pipeline with a group of plugs.
-}
nest :
    Plug config model msg
    -> Plug config model msg
    -> Plug config model msg
nest plug pipeline =
    case ( pipeline, plug ) of
        ( Pipeline begin, Pipeline end ) ->
            Array.append begin end |> Pipeline

        ( Pipeline begin, _ ) ->
            begin |> Array.push plug |> Pipeline

        ( _, Pipeline end ) ->
            Array.append (Array.fromList [ pipeline ]) end |> Pipeline

        _ ->
            Array.fromList [ pipeline, plug ] |> Pipeline


{-| Extend the pipeline with a simple plug.

A plug just transforms the connection. For example,

    pipeline
        |> plug (body (TextBody "foo"))
-}
plug :
    (Conn config model -> Conn config model)
    -> Plug config model msg
    -> Plug config model msg
plug func =
    nest (Simple func)


{-| Extends the pipeline with an update plug.

An update plug can transform the connection and or return a side effect (`Cmd`).
Loop plugs should use `pipelinePause` and `pipelineResume` when working with side
effects. See [Pipeline Processing](#pipeline-processing) for more.

    -- Loop plug which does nothing
    pipeline
        |> loop (\msg conn -> (conn, Cmd.none))
-}
loop :
    (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    -> Plug config model msg
    -> Plug config model msg
loop func =
    nest (Update func)


{-| Adds a router to the pipeline.

A router can branch a pipeline into many smaller pipelines depending on the
route message passed in. See [Routing](#routing) for more.
-}
fork :
    (Conn config model -> Plug config model msg)
    -> Plug config model msg
    -> Plug config model msg
fork func =
    nest (Router func)



-- ROUTING


{-| Parse a connection request path into nicely formatted elm data.

    import UrlParser exposing (Parser, (</>), s, int, top, map, oneOf)
    import Serverless.Conn exposing (parseRoute)


    type Route
        = Home
        | Cheers Int
        | NotFound


    route : Parser (Route -> a) a
    route =
        oneOf
            [ map Home top
            , map Cheers (s "cheers" </> int)
            ]


    myRouter : Conn -> Plug
    myRouter conn =
        case
            ( conn.req.method
            , conn |> parseRoute route NotFound
            )
        of
            ( GET, Home ) ->
                -- pipeline for home...

            ( GET, Cheers numTimes ) ->
                -- pipeline for cheers...

            _ ->
                -- pipeline for 404 not found...
-}
parseRoute : Parser (route -> route) route -> route -> Conn config model -> route
parseRoute router defaultRoute conn =
    UrlParser.parse router conn.req.path Dict.empty
        |> Maybe.withDefault defaultRoute



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


{-| Sets the given string as the response body.

Also sets the `Content-Type` to `text/text`.
-}
textBody : String -> Conn config model -> Conn config model
textBody val =
    body (TextBody val)
        >> header ( "content-type", "text/text; charset=utf-8" )


{-| Sets the given JSON value as the response body.

Also sets the `Content-Type` to `application/json`.
-}
jsonBody : J.Value -> Conn config model -> Conn config model
jsonBody val =
    body (JsonBody val)
        >> header ( "content-type", "application/json; charset=utf-8" )


{-| Set a response header.

If you set the same response header more than once, the second value will
override the first.
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


{-| Alias for `status (Code value)`
-}
statusCode : Int -> Conn config model -> Conn config model
statusCode value =
    status (Code value)


{-| Sends a connection response through the given port
-}
send : ResponsePort msg -> Conn config model -> ( Conn config model, Cmd msg )
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


{-| Convert a connection transformer into a plug which sends the response.

Good for quickly creating a pipeline inside a router.

    router : Conn -> Plug
    router conn =
        case
            ( conn.req.method
            , conn |> parseRoute route NotFound
            )
        of
            -- other cases...

            _ ->
                toResponder responsePort <|
                    \conn ->
                        conn
                            |> statusCode 404
                            |> textBody ("Nothing at: " ++ conn.req.path)
-}
toResponder : ResponsePort msg -> (Conn config model -> Conn config model) -> Plug config model msg
toResponder port_ func =
    Update (\msg -> func >> send port_)



-- RESPONDING WITH ERRORS


{-| Respond with a 500 internal server error.

The given value is converted to a string and set to the response body.
-}
internalError : Body -> Conn config model -> Conn config model
internalError body =
    (case body of
        JsonBody json ->
            jsonBody json

        TextBody text ->
            textBody text

        NoBody ->
            (\conn -> conn)
    )
        >> status (Code 500)


{-| Respond with an unexpected message error.

Use this in the `case msg of` catch-all (`_ ->`) for any messages that you do
not expect to receive in a loop plug.
-}
unexpectedMsg : msg -> Conn config model -> Conn config model
unexpectedMsg msg =
    ("unexpected msg: "
        ++ (msg |> toString)
        |> textBody
    )
        >> status (Code 500)



-- Pipeline Processing


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
increment is negative. A pause increment of zero will have no effect.
-}
pipelinePause :
    Int
    -> Cmd msg
    -> ResponsePort msg
    -> Conn config model
    -> ( Conn config model, Cmd msg )
pipelinePause i cmd port_ conn =
    if i < 0 then
        conn
            |> internalError (TextBody "pause pipeline called with negative value")
            |> send port_
    else
        ( case conn.pipelineState of
            Processing ->
                case i of
                    0 ->
                        conn

                    _ ->
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
count goes below zero. A resume increment of zero will have no effect.
-}
pipelineResume :
    Int
    -> ResponsePort msg
    -> Conn config model
    -> ( Conn config model, Cmd msg )
pipelineResume i port_ conn =
    if i < 0 then
        conn
            |> internalError (TextBody "resume pipeline called with negative value")
            |> send port_
    else
        case conn.pipelineState of
            Processing ->
                case i of
                    0 ->
                        ( conn, Cmd.none )

                    _ ->
                        conn
                            |> internalError
                                (TextBody "resume pipeline called, but processing was not paused")
                            |> send port_

            Paused j ->
                if j - i > 0 then
                    ( { conn | pipelineState = Paused (j - i) }, Cmd.none )
                else if j - i == 0 then
                    ( { conn | pipelineState = Processing }, Cmd.none )
                else
                    conn
                        |> internalError (TextBody "resume pipeline underflow")
                        |> send port_



-- APPLICATION SPECIFIC


{-| Transform and update the application defined model stored in the connection.
-}
updateModel : (model -> model) -> Conn config model -> Conn config model
updateModel update conn =
    { conn | model = update conn.model }
