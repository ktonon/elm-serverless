module Serverless.Plug exposing (Plug(..), Pipeline, pipeline, plug, loop, nest)

{-| Build pipelines of plugs.

@docs Plug, Pipeline, pipeline, plug, loop, nest
-}

import Serverless.Conn.Types exposing (Conn)


{-| A plug processes the connection in some way.

There are three types:

* `Plug` a simple plug. It just transforms the connection
* `Loop` an update plug. It may transform the connection, but it also can
  have side effects. Execution will only flow to the next plug when an
  update plug returns no side effects.
* `Pipeline` a sequence of zero or more plugs
-}
type Plug config model msg
    = Plug (Conn config model -> Conn config model)
    | Loop (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    | Pipeline (Pipeline config model msg)


{-| Represents a list of plugs, each of which processes the connection
-}
type alias Pipeline config model msg =
    List (Plug config model msg)


{-| Begins a pipeline.

Build the pipeline by chaining simple and update plugs with
`|> plug` and `|> loop` respectively.
-}
pipeline : Pipeline config model msg
pipeline =
    []


{-| Extend the pipeline with a simple plug.

A plug just transforms the connection. For example,

    pipeline
        |> plug (body TextBody "foo")
-}
plug :
    (Conn config model -> Conn config model)
    -> Pipeline config model msg
    -> Pipeline config model msg
plug plug pipeline =
    (wrapPlug plug) :: pipeline


wrapPlug :
    (Conn config model -> Conn config model)
    -> Plug config model msg
wrapPlug plug =
    Plug plug


{-| Extends the pipeline with an update plug.

An update plug can transform the connection and or return a side effect (`Cmd`).
Execution will only flow to the next plug when an update plug returns no side
effects.

For example,

    pipeline
        |> loop (\msg conn -> (conn, Cmd.none))
-}
loop :
    (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    -> Pipeline config model msg
    -> Pipeline config model msg
loop update pipeline =
    (wrapLoop (List.length pipeline) update) :: pipeline


wrapLoop :
    Int
    -> (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    -> Plug config model msg
wrapLoop index update =
    Loop update


{-| Nest a child pipeline into a parent pipeline.
-}
nest :
    Pipeline config model msg
    -> Pipeline config model msg
    -> Pipeline config model msg
nest child parent =
    Pipeline child :: parent
