module Serverless.Pipeline
    exposing
        ( Msg(..)
        , Options
        , PlugMsg(..)
        , apply
        , firstIndexPath
        , newOptions
        )

import Array exposing (Array)
import Json.Encode
import Serverless.Conn as Conn exposing (Conn, respond)
import Serverless.Conn.Request exposing (Id)
import Serverless.Plug as Plug exposing (Outcome(..), Plug)


-- MODEL


type Msg msg
    = RawRequest Json.Encode.Value
    | HandlerMsg Id (PlugMsg msg)


type PlugMsg msg
    = PlugMsg IndexPath msg


type alias UnwrappedPlugMsg config model route msg =
    { msg : msg
    , indexPath : IndexPath
    , index : Index
    , plug : Plug config model route msg
    }


type alias Index =
    Int


type alias IndexPath =
    Array Index


firstIndexPath : IndexPath
firstIndexPath =
    Array.empty |> Array.push 0


type alias Options config model route msg =
    { appCmdAcc : Cmd (Msg msg)
    , indexDepth : IndexDepth
    , endpoint : msg
    , pipeline : Plug config model route msg
    }


newOptions : msg -> Plug config model route msg -> Options config model route msg
newOptions =
    Options Cmd.none 0


type alias IndexDepth =
    Int



-- PIPELINE PROCESSING


apply :
    Options config model route msg
    -> PlugMsg msg
    -> Conn config model route
    -> ( Conn config model route, Cmd (Msg msg) )
apply opt plugMsg conn =
    case plugMsg |> unwrapPlugMsg opt of
        Nothing ->
            ( conn, opt.appCmdAcc )

        Just upm ->
            applyUnwrappedPlugMsg opt upm conn


applyUnwrappedPlugMsg :
    Options config model route msg
    -> UnwrappedPlugMsg config model route msg
    -> Conn config model route
    -> ( Conn config model route, Cmd (Msg msg) )
applyUnwrappedPlugMsg opt upm conn =
    let
        ( newConn, appCmd ) =
            applyPlug opt upm conn

        newOpt =
            addAppCmd appCmd opt
    in
    if Conn.isActive newConn then
        apply
            newOpt
            (PlugMsg
                -- Move on to the next plug in the pipeline
                -- at the same depth
                (upm.indexPath
                    |> Array.set
                        newOpt.indexDepth
                        (upm.index + 1)
                )
                -- New plugs always receive the endpoint
                -- as the first message
                newOpt.endpoint
            )
            newConn
    else
        ( newConn, newOpt.appCmdAcc )


applyPlug :
    Options config model route msg
    -> UnwrappedPlugMsg config model route msg
    -> Conn config model route
    -> ( Conn config model route, Cmd (Msg msg) )
applyPlug opt { indexPath, msg, plug } conn =
    case Plug.apply plug msg conn of
        NextConn ( conn, cmd ) ->
            ( conn
            , cmd
                |> Cmd.map (PlugMsg indexPath)
                |> Cmd.map (HandlerMsg (Conn.id conn))
            )

        NextPipeline pipeline ->
            let
                nextIndexPath =
                    if (indexPath |> Array.length) < opt.indexDepth + 2 then
                        indexPath |> Array.push 0
                    else
                        indexPath
            in
            apply
                { opt
                    | pipeline = pipeline
                    , indexDepth = opt.indexDepth + 1
                }
                (PlugMsg nextIndexPath msg)
                conn


addAppCmd : Cmd (Msg msg) -> Options config model route msg -> Options config model route msg
addAppCmd cmd opt =
    { opt | appCmdAcc = Cmd.batch [ cmd, opt.appCmdAcc ] }


unwrapPlugMsg : Options config model route msg -> PlugMsg msg -> Maybe (UnwrappedPlugMsg config model route msg)
unwrapPlugMsg opt (PlugMsg indexPath msg) =
    indexPath
        |> Array.get opt.indexDepth
        |> Maybe.andThen
            (\index ->
                Plug.get index opt.pipeline
                    |> Maybe.map (UnwrappedPlugMsg msg indexPath index)
            )
