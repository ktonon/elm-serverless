module Serverless.Plug
    exposing
        ( Plug
        , apply
        , nest
        , pipeline
        , plug
        , size
        )

{-| A **pipeline** is a sequence of functions which transform the connection,
optionally sending back an HTTP response at each step. We use the term **plug**
to mean a single function that is part of the pipeline. But a pipeline is also
just a plug and so pipelines can be composed from other pipelines.

Examples below assume the following imports:

    import Serverless.Conn exposing (updateResponse)
    import Serverless.Conn.Body exposing (text)
    import Serverless.Conn.Response exposing (addHeader, setBody, setStatus)

@docs Plug


## Building Pipelines

Use these functions to build your pipelines.

@docs pipeline, plug, nest


## Applying Pipelines

@docs apply


## Misc

These functions are typically not needed when building an application. They are
used internally by the framework. They are useful when debugging or writing unit
tests.

@docs size

-}

import Serverless.Conn as Conn exposing (Conn)


{-| Represents a pipeline or section of a pipeline.
-}
type Plug config model route interop
    = Simple (Conn config model route interop -> Conn config model route interop)
    | Pipeline (List (Plug config model route interop))



-- CONSTRUCTORS


{-| Begins a pipeline.

Build the pipeline by chaining plugs with plug, loop, fork, and nest.

    size pipeline
    --> 0

-}
pipeline : Plug config model route interop
pipeline =
    Pipeline []


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
        |> size
    --> 2

-}
nest :
    Plug config model route interop
    -> Plug config model route interop
    -> Plug config model route interop
nest a b =
    case ( a, b ) of
        ( Pipeline begin, Pipeline end ) ->
            Pipeline <| List.append begin end

        ( Pipeline begin, _ ) ->
            Pipeline <| List.append begin [ b ]

        ( _, Pipeline end ) ->
            Pipeline <| a :: end

        _ ->
            Pipeline [ a, b ]


{-| Extend the pipeline with a simple plug.

A plug just transforms the connection. For example,

    pipeline
        |> plug (updateResponse <| setBody <| text "Ok" )
        |> plug (updateResponse <| setStatus 200)
        |> size
    --> 2

-}
plug :
    (Conn config model route interop -> Conn config model route interop)
    -> Plug config model route interop
    -> Plug config model route interop
plug func =
    nest (Simple func)


{-| Basic pipeline update function.
-}
apply :
    Plug config model route interop
    -> Conn config model route interop
    -> Conn config model route interop
apply plug conn =
    case ( Conn.unsent conn, plug ) of
        ( Nothing, _ ) ->
            conn

        ( _, Simple transform ) ->
            transform conn

        ( _, Pipeline plugs ) ->
            List.foldl
                (\plug ->
                    apply plug
                )
                conn
                plugs



-- MISC


{-| The number of plugs in a pipeline
-}
size : Plug config model route interop -> Int
size plug =
    case plug of
        Simple _ ->
            1

        Pipeline plugs ->
            List.length plugs
