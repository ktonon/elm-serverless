module Serverless.Plug exposing (..)

{-| Build pipelines of plugs.

Use these functions to build your pipelines. For example,

    myPipeline =
        pipeline
            |> plug simplePlugA
            |> plug simplePlugB
            |> loop loadSomeDatabaseStuff
            |> nest anotherPipeline
            |> fork router

@docs pipeline, toPipeline, plug, loop, nest, fork
-}

import Array
import Serverless.Types exposing (..)


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
