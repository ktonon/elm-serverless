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
single function that is part of the pipeline.

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

@docs pipeline, toPipeline, plug, loop, nest, fork

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

@docs body, header, status, send

## Responding with Errors

The following functions set the HTTP status code to 500 and send a response
with an error message.

@docs internalError, unexpectedMsg

## Routing

@docs parseRoute

## Pipeline Processing

The following functions can be used inside of a loop plug which needs to wait for
the results of a side effect.

@docs pipelinePause, pipelineResume

## Application Specific

@docs updateModel
-}

import Array
import Dict
import Serverless.Pool exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Types exposing (..)
import UrlParser exposing (Parser, (</>), oneOf, parse, map, int, s)


-- BUILDING PIPELINES


{-| Begins a pipeline.

Build the pipeline by chaining simple and update plugs with
`|> plug` and `|> loop` respectively.
-}
pipeline : Pipeline config model msg
pipeline =
    Array.empty


{-| Converts a single function to a pipeline.

For creating a simple pipeline from a responder function when a pipeline is
expected.

    status (Code 404)
        >> body (TextBody "Not found")
        >> send responsePort
        |> toPipeline
-}
toPipeline :
    (Conn config model -> ( Conn config model, Cmd msg ))
    -> Pipeline config model msg
toPipeline responder =
    pipeline |> loop (\msg conn -> conn |> responder)


{-| Extend the pipeline with a simple plug.

A plug just transforms the connection. For example,

    pipeline
        |> plug (body (TextBody "foo"))
-}
plug :
    (Conn config model -> Conn config model)
    -> Pipeline config model msg
    -> Pipeline config model msg
plug plug pipeline =
    pipeline |> Array.push (Plug plug)


{-| Extends the pipeline with an update plug.

An update plug can transform the connection and or return a side effect (`Cmd`).
Loop plugs should use `pipelinePause` and `pipelineResume` when working with side
effects. They are defined in the `Serverless.Conn` module.

    -- Loop plug which does nothing
    pipeline
        |> loop (\msg conn -> (conn, Cmd.none))
-}
loop :
    (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    -> Pipeline config model msg
    -> Pipeline config model msg
loop update pipeline =
    pipeline |> Array.push (Loop update)


{-| Nest a child pipeline into a parent pipeline.
-}
nest :
    Pipeline config model msg
    -> Pipeline config model msg
    -> Pipeline config model msg
nest child parent =
    Array.append parent child


{-| Adds a router to the pipeline.

A router can branch a pipeline into many smaller pipelines depending on the
route message passed in.
-}
fork :
    (Conn config model -> Pipeline config model msg)
    -> Pipeline config model msg
    -> Pipeline config model msg
fork router pipeline =
    pipeline |> Array.push (Router router)



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


    myRouter : Conn -> Pipeline
    myRouter conn =
        case (conn.req.method, conn |> parseRoute route NotFound ) of
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



-- RESPONDING WITH ERRORS


{-| Respond with a 500 internal server error.

The given value is converted to a string and set to the response body.
-}
internalError : Body -> ResponsePort msg -> Conn config model -> ( Conn config model, Cmd msg )
internalError val port_ =
    status (Code 500)
        >> body val
        >> send port_


{-| Respond with an unexpected message error.

Use this in the `case msg of` catch-all (`_ ->`) for any messages that you do
not expect to receive in a loop plug.
-}
unexpectedMsg : msg -> ResponsePort msg -> Conn config model -> ( Conn config model, Cmd msg )
unexpectedMsg msg =
    internalError ("unexpected msg: " ++ (msg |> toString) |> TextBody)



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
pipelinePause : Int -> Cmd msg -> ResponsePort msg -> Conn config model -> ( Conn config model, Cmd msg )
pipelinePause i cmd port_ conn =
    if i < 0 then
        conn |> internalError (TextBody "pause pipeline called with negative value") port_
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
pipelineResume : Int -> ResponsePort msg -> Conn config model -> ( Conn config model, Cmd msg )
pipelineResume i port_ conn =
    if i < 0 then
        conn |> internalError (TextBody "resume pipeline called with negative value") port_
    else
        case conn.pipelineState of
            Processing ->
                case i of
                    0 ->
                        ( conn, Cmd.none )

                    _ ->
                        conn |> internalError (TextBody "resume pipeline called, but processing was not paused") port_

            Paused j ->
                if j - i > 0 then
                    ( { conn | pipelineState = Paused (j - i) }, Cmd.none )
                else if j - i == 0 then
                    ( { conn | pipelineState = Processing }, Cmd.none )
                else
                    conn |> internalError (TextBody "resume pipeline underflow") port_



-- APPLICATION SPECIFIC


{-| Transform and update the application defined model stored in the connection.
-}
updateModel : (model -> model) -> Conn config model -> Conn config model
updateModel update conn =
    { conn | model = update conn.model }
