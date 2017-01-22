module Serverless.Plug.Private exposing (..)

import Array exposing (Array)
import Serverless.Conn.Types exposing (..)
import Serverless.Plug exposing (..)


type alias PlugIndex =
    Int


type PlugMsg msg
    = PlugMsg PlugIndex msg


type alias BakedPipeline config model msg =
    Array (BakedPlug config model msg)


type BakedPlug config model msg
    = BakedPlug (Conn config model -> Conn config model)
    | BakedLoop (msg -> Conn config model -> ( Conn config model, Cmd msg ))


bakePipeline : Pipeline config model msg -> BakedPipeline config model msg
bakePipeline rawPipeline =
    rawPipeline
        |> List.foldr bakePlugInto Array.empty


bakePlugInto :
    Plug config model msg
    -> BakedPipeline config model msg
    -> BakedPipeline config model msg
bakePlugInto plug bakedPipeline =
    case plug of
        Plug transformConn ->
            bakedPipeline |> Array.push (BakedPlug transformConn)

        Loop update ->
            bakedPipeline |> Array.push (BakedLoop update)

        Pipeline pipeline ->
            Array.append bakedPipeline (bakePipeline pipeline)


applyPipeline :
    msg
    -> BakedPipeline config model msg
    -> PlugMsg msg
    -> Conn config model
    -> ( Conn config model, Cmd (PlugMsg msg) )
applyPipeline endpoint pipeline plugMsg conn =
    case plugMsg of
        PlugMsg index msg ->
            case pipeline |> Array.get index of
                Just plug ->
                    let
                        ( newConn, cmd ) =
                            conn |> applyPlug plug index msg
                    in
                        if cmd == Cmd.none then
                            newConn
                                |> applyPipeline
                                    endpoint
                                    pipeline
                                    (PlugMsg (index + 1) endpoint)
                        else
                            ( newConn, cmd |> Cmd.map (PlugMsg index) )

                Nothing ->
                    ( conn, Cmd.none )


applyPlug :
    BakedPlug config model msg
    -> PlugIndex
    -> msg
    -> Conn config model
    -> ( Conn config model, Cmd msg )
applyPlug plug index msg conn =
    case plug of
        BakedPlug transform ->
            ( conn |> transform, Cmd.none )

        BakedLoop update ->
            conn |> update msg
