module Serverless.Types exposing (..)

{-| Types that define a Serverless.Program

These are all types which are parameterized by specific types which you define.

To make your program more readable, you should consider defining your own `Types`
module which provides concrete types for each of the type variables. See the
[demo](https://github.com/ktonon/elm-serverless/blob/master/demo/src/Types.elm)
for an example.

## Pipeline

@docs Pipeline, Plug, Conn, Sendable, PipelineState

## Ports

An elm library cannot expose a module with ports. The following port definitions
are provided so that your program can create the necessary request and response
ports.

@docs RequestPort, ResponsePort
-}

import Array exposing (Array)
import Json.Encode as J
import Serverless.Conn.Types exposing (..)


-- PIPELINE


{-| Represents a list of plugs, each of which processes the connection
-}
type alias Pipeline config model msg =
    Array (Plug config model msg)


{-| A plug processes the connection in some way.

There are three types:

* `Plug` a simple plug. It just transforms the connection
* `Loop` an update plug. It may transform the connection, but it also can
  have side effects. Execution will only flow to the next plug when an
  update plug returns no side effects.
* `Router` a function which accepts a connection and returns a new pipeline
  which is a specialized handler for that type of connection.
-}
type Plug config model msg
    = Plug (Conn config model -> Conn config model)
    | Loop (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    | Router (Conn config model -> Pipeline config model msg)


{-| A connection with a request and response.

Connections are parameterized with config and model record types which are
specific to the application. Config is loaded once on app startup, while model
is set to a provided initial value for each incomming request.
-}
type alias Conn config model =
    { pipelineState : PipelineState
    , config : config
    , req : Request
    , resp : Sendable Response
    , model : model
    }


{-| A sendable type cannot be accessed after it is sent
-}
type Sendable a
    = Unsent a
    | Sent


{-| State of the pipeline for this connection.
-}
type PipelineState
    = Processing
    | Paused Int



-- PORTS


{-| Type of port through which the request is received.
Set your request port to this type.
-}
type alias RequestPort msg =
    (J.Value -> msg) -> Sub msg


{-| Type of port through which the request is sent.
Set your response port to this type.
-}
type alias ResponsePort msg =
    J.Value -> Cmd msg
