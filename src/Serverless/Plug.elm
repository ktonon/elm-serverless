module Serverless.Plug
    exposing
        ( Plug(..)
        , fork
        , loop
        , nest
        , pipeline
        , plug
        , responder
        , size
        , inspect
        )

{-|
A __pipeline__ is a sequence of functions which transform the connection,
eventually sending back the HTTP response. We use the term __plug__ to mean a
single function that is part of the pipeline. But a pipeline is also just a plug
and so pipelines can be composed from other pipelines.

Examples assume the following imports:

    import Serverless.Conn exposing (id, method, respond, send, updateResponse)
    import Serverless.Conn.Body exposing (text)
    import Serverless.Conn.Request exposing (Method(..))
    import Serverless.Conn.Response exposing (addHeader, setBody, setStatus)
    import TestHelpers exposing (appendToBody, responsePort)

@docs Plug

## Building Pipelines

Use these functions to build your pipelines.

@docs pipeline, plug, loop, fork, nest, responder, size, inspect
-}

import Array exposing (Array)
import Serverless.Conn as Conn exposing (Conn)
import Serverless.Conn.Body as Body exposing (Body)
import Serverless.Conn.Response exposing (Status)
import Serverless.Port as Port


{-| A plug processes the connection in some way.

There are four types:

* `Simple` a simple plug. It just transforms the connection
* `Update` an update plug. It may transform the connection, but it also can
  have side effects. Execution will only flow to the next plug when an
  update plug returns no side effects.
* `Router` a function which accepts a connection and returns a new pipeline
  which is a specialized handler for that type of connection.
* `Pipeline` a sequence of zero or more plugs.
-}
type Plug config model msg
    = Simple (Conn config model -> Conn config model)
    | Update (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    | Router (Conn config model -> Plug config model msg)
    | Pipeline (Array (Plug config model msg))



-- CONSTRUCTORS


{-| Begins a pipeline.

Build the pipeline by chaining plugs with plug, loop, fork, and nest.

    pipeline
        |> inspect
    --> "[]"
-}
pipeline : Plug config model msg
pipeline =
    Pipeline Array.empty


{-| Extends the pipeline with a plug.

This is the most general of the pipeline building functions. Since it just
accepts a plug, and since a plug can be a pipeline, it can be used to extend a
pipeline with a group of plugs.

    pipeline
        |> nest (pipeline
                    |> plug (updateResponse <| addHeader ( "key", "value" ))
                    -- ...
                )
        |> plug (updateResponse <| setStatus 200)
        |> inspect
    --> "[Simple, Simple]"
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
        |> plug (updateResponse <| setBody <| text "Ok" )
        |> plug (updateResponse <| setStatus 200)
        |> inspect
    --> "[Simple, Simple]"
-}
plug :
    (Conn config model -> Conn config model)
    -> Plug config model msg
    -> Plug config model msg
plug func =
    nest (Simple func)


{-| Extends the pipeline with an update plug.

An update plug can transform the connection and or return a side effect (`Cmd`).
Loop plugs should use `pause` and `resume` when working with side
effects. See [Waiting for Side-Effects](./Serverless-Conn#waiting-for-side-effects) for more.

    pipeline
        |> loop (\msg conn -> (conn, Cmd.none))
        |> inspect
    --> "[Update]"
-}
loop :
    (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    -> Plug config model msg
    -> Plug config model msg
loop func =
    nest (Update func)


{-| Adds a router to the pipeline.

A router can branch a pipeline into many smaller pipelines depending on the
route message passed in. See [Conn.parseRoute](./Serverless-Conn#parseRoute) for more.

    pipeline
        |> fork
            (\conn ->
                case method conn of
                    GET ->
                        pipeline
                            |> plug (appendToBody "some pipeline...")
                            |> plug (appendToBody "...for get")
                            -- ...
                    _ ->
                        pipeline
                            -- handle other cases...
            )
        |> inspect
    --> "[Router]"
-}
fork :
    (Conn config model -> Plug config model msg)
    -> Plug config model msg
    -> Plug config model msg
fork func =
    nest (Router func)



-- HELPERS


{-| Same as [Conn.respond](./Serverless-Conn#respond), but plugable into a pipeline.

    inspect <|
        responder responsePort <|
            \conn ->
                ( 200
                , text <| (++) "Id: " <| id conn
                )
    --> "[Update]"
-}
responder :
    Port.Response msg
    -> (Conn config model -> ( Status, Body ))
    -> Plug config model msg
responder port_ f =
    pipeline
        |> loop (\_ conn -> Conn.respond port_ (f conn) conn)



-- GETTERS


{-| The number of plugs in a pipeline
-}
size : Plug config model msg -> Int
size plug =
    case plug of
        Simple _ ->
            1

        Update _ ->
            1

        Router _ ->
            1

        Pipeline plugs ->
            Array.length plugs


{-| Inspect the general shape of the pipeline.
-}
inspect : Plug config model msg -> String
inspect plug =
    case plug of
        Simple _ ->
            "Simple"

        Update _ ->
            "Update"

        Router _ ->
            "Router"

        Pipeline plugs ->
            "["
                ++ (plugs
                        |> Array.toList
                        |> List.map inspect
                        |> String.join ", "
                   )
                ++ "]"
