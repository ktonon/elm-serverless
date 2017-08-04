module Serverless.Plug
    exposing
        ( Outcome(..)
        , Plug
        , apply
        , fork
        , get
        , inspect
        , loop
        , nest
        , pipeline
        , plug
        , responder
        , size
        )

{-| A **pipeline** is a sequence of functions which transform the connection,
eventually sending back the HTTP response. We use the term **plug** to mean a
single function that is part of the pipeline. But a pipeline is also just a plug
and so pipelines can be composed from other pipelines.

Examples below assume the following imports:

    import Serverless.Conn exposing (id, method, respond, send, updateResponse)
    import Serverless.Conn.Body exposing (text)
    import Serverless.Conn.Request exposing (Method(..))
    import Serverless.Conn.Response exposing (addHeader, setBody, setStatus)
    import TestHelpers exposing (appendToBody, responsePort, simpleLoop)

@docs Plug


## Building Pipelines

Use these functions to build your pipelines.

@docs pipeline, plug, loop, responder, fork, nest


## Misc

These functions are typically not needed when building an application. They are
used internally by the framework. They are useful when debugging or writing unit
tests.

@docs Outcome, apply, get, size, inspect

-}

import Array exposing (Array)
import Serverless.Conn as Conn exposing (Conn)
import Serverless.Conn.Body as Body exposing (Body)
import Serverless.Conn.Response exposing (Status)
import Serverless.Port as Port


{-| Represents a pipeline or section of a pipeline.
-}
type Plug config model route msg
    = Simple (Conn config model route -> Conn config model route)
    | Update (msg -> Conn config model route -> ( Conn config model route, Cmd msg ))
    | Router (Conn config model route -> Plug config model route msg)
    | Pipeline (Array (Plug config model route msg))



-- CONSTRUCTORS


{-| Begins a pipeline.

Build the pipeline by chaining plugs with plug, loop, fork, and nest.

    pipeline
        |> inspect
    --> "[]"

-}
pipeline : Plug config model route msg
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
    Plug config model route msg
    -> Plug config model route msg
    -> Plug config model route msg
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
    (Conn config model route -> Conn config model route)
    -> Plug config model route msg
    -> Plug config model route msg
plug func =
    nest (Simple func)


{-| Extends the pipeline with an update plug.

An update plug can transform the connection and or return a side effect (`Cmd`).
Loop plugs should use `pause` and `resume` when working with side
effects. See [Waiting for Side-Effects](./Serverless-Conn#waiting-for-side-effects) for more.

    pipeline
        |> loop
            (\msg conn ->
                conn
                    -- Usually to a `case of` on msg
                    |> updateResponse
                        (\resp ->
                            resp
                                |> setBody (text "Ok")
                                |> setStatus 200
                        )
                    |> send responsePort
            )
        |> inspect
    --> "[Update]"

-}
loop :
    (msg -> Conn config model route -> ( Conn config model route, Cmd msg ))
    -> Plug config model route msg
    -> Plug config model route msg
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
    (Conn config model route -> Plug config model route msg)
    -> Plug config model route msg
    -> Plug config model route msg
fork func =
    nest (Router func)


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
    -> (Conn config model route -> ( Status, Body ))
    -> Plug config model route msg
responder port_ f =
    pipeline
        |> loop (\_ conn -> Conn.respond port_ (f conn) conn)



-- MISC


{-| Gets a child plug at the given index.

    pipeline
        |> get 0
    --> Nothing

    pipeline
        |> plug (appendToBody "a")
        |> (get 0 >> toString)
    --> "Just (Simple <function>)"

    pipeline
        |> plug (appendToBody "a")
        |> get 0
        |> Maybe.andThen (get 0)
    --> Nothing

-}
get : Int -> Plug config model route msg -> Maybe (Plug config model route msg)
get index plug =
    case plug of
        Pipeline pipeline ->
            case pipeline |> Array.get index of
                Nothing ->
                    Nothing

                Just childPlug ->
                    Just childPlug

        _ ->
            Nothing


{-| Inspect the general shape of the pipeline.
-}
inspect : Plug config model route msg -> String
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


{-| The number of plugs in a pipeline
-}
size : Plug config model route msg -> Int
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


{-| Outcome of applying a plug to a connection.
-}
type Outcome config model route msg
    = NextConn ( Conn config model route, Cmd msg )
    | NextPipeline (Plug config model route msg)


{-| Basic pipeline update function.
-}
apply :
    Plug config model route msg
    -> msg
    -> Conn config model route
    -> Outcome config model route msg
apply plug msg conn =
    case plug of
        Simple transform ->
            NextConn <| ( transform conn, Cmd.none )

        Update update ->
            NextConn <| update msg conn

        Router router ->
            NextPipeline <| router conn

        Pipeline nested ->
            Debug.crash "pipeline was not flatted"
