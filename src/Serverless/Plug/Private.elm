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
    -> List (Cmd (PlugMsg msg))
    -> Conn config model
    -> ( Conn config model, Cmd (PlugMsg msg) )
applyPipeline endpoint pipeline plugMsg plugCmdAcc conn =
    case plugMsg of
        PlugMsg index msg ->
            case pipeline |> Array.get index of
                Just plug ->
                    let
                        ( newConn, cmd ) =
                            conn |> applyPlug plug index msg

                        plugCmd =
                            cmd |> Cmd.map (PlugMsg index)

                        newPlugCmdAcc =
                            plugCmd :: plugCmdAcc
                    in
                        case newConn.resp of
                            Unsent _ ->
                                case newConn.pipelineState of
                                    Processing ->
                                        newConn
                                            |> applyPipeline
                                                endpoint
                                                pipeline
                                                (PlugMsg (index + 1) endpoint)
                                                newPlugCmdAcc

                                    Paused _ ->
                                        ( newConn, Cmd.batch newPlugCmdAcc )

                            Sent ->
                                ( newConn, Cmd.batch newPlugCmdAcc )

                Nothing ->
                    ( conn, Cmd.batch plugCmdAcc )


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
