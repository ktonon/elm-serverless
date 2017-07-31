module Serverless.Pipeline
    exposing
        ( Msg(..)
        , PlugMsg(..)
        , Options
        , apply
        , firstIndexPath
        , newOptions
        )

import Array exposing (Array)
import Json.Encode
import Serverless.Conn as Conn exposing (Conn, respond)
import Serverless.Conn.Request exposing (Id)
import Serverless.Plug as Plug exposing (Plug(..))


-- MODEL


type Msg msg
    = RawRequest Json.Encode.Value
    | HandlerMsg Id (PlugMsg msg)


type PlugMsg msg
    = PlugMsg IndexPath msg


type alias UnwrappedPlugMsg config model msg =
    { msg : msg
    , indexPath : IndexPath
    , index : Index
    , plug : Plug config model msg
    }


type alias Index =
    Int


type alias IndexPath =
    Array Index


firstIndexPath : IndexPath
firstIndexPath =
    Array.empty |> Array.push 0


type alias Options config model msg =
    { appCmdAcc : Cmd (Msg msg)
    , indexDepth : IndexDepth
    , endpoint : msg
    , pipeline : Plug config model msg
    }


newOptions : msg -> Plug config model msg -> Options config model msg
newOptions =
    Options Cmd.none 0


type alias IndexDepth =
    Int



-- PIPELINE PROCESSING


apply :
    Options config model msg
    -> PlugMsg msg
    -> Conn config model
    -> ( Conn config model, Cmd (Msg msg) )
apply opt plugMsg conn =
    case plugMsg |> unwrapPlugMsg opt of
        Nothing ->
            ( conn, opt.appCmdAcc )

        Just upm ->
            conn |> applyUnwrappedPlugMsg opt upm


applyUnwrappedPlugMsg :
    Options config model msg
    -> UnwrappedPlugMsg config model msg
    -> Conn config model
    -> ( Conn config model, Cmd (Msg msg) )
applyUnwrappedPlugMsg opt upm conn =
    let
        ( newConn, appCmd ) =
            conn |> applyPlug opt upm

        newOpt =
            opt |> addAppCmd appCmd
    in
        if Conn.isActive newConn then
            newConn
                |> apply
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
        else
            ( newConn, newOpt.appCmdAcc )


applyPlug :
    Options config model msg
    -> UnwrappedPlugMsg config model msg
    -> Conn config model
    -> ( Conn config model, Cmd (Msg msg) )
applyPlug opt upm conn =
    case upm.plug of
        Simple transform ->
            ( conn |> transform
            , Cmd.none
            )

        Update update ->
            let
                ( newConn, cmd ) =
                    conn |> update upm.msg
            in
                ( newConn
                , cmd
                    |> Cmd.map (PlugMsg upm.indexPath)
                    |> Cmd.map (HandlerMsg (Conn.id conn))
                )

        Router router ->
            conn
                -- Increase the pipeline depth, updates the index path to make
                -- sure it is long enough given the new depth, and changes the
                -- active pipeline to that which is returned from the router.
                |>
                    incrementIndexDepth
                        (opt |> updatePipelineFromRouter router conn)
                        upm

        Pipeline nested ->
            Debug.crash "pipeline was not flatted"


updatePipelineFromRouter :
    (Conn config model -> Plug config model msg)
    -> Conn config model
    -> Options config model msg
    -> Options config model msg
updatePipelineFromRouter router conn opt =
    conn
        |> router
        |> (\pl -> { opt | pipeline = pl })


incrementIndexDepth :
    Options config model msg
    -> UnwrappedPlugMsg config model msg
    -> Conn config model
    -> ( Conn config model, Cmd (Msg msg) )
incrementIndexDepth opt upm conn =
    conn
        |> apply
            { opt | indexDepth = opt.indexDepth + 1 }
            (PlugMsg
                (if (upm.indexPath |> Array.length) < opt.indexDepth + 2 then
                    upm.indexPath |> Array.push 0
                 else
                    upm.indexPath
                )
                upm.msg
            )


addAppCmd : Cmd (Msg msg) -> Options config model msg -> Options config model msg
addAppCmd cmd opt =
    { opt | appCmdAcc = Cmd.batch [ cmd, opt.appCmdAcc ] }


unwrapPlugMsg : Options config model msg -> PlugMsg msg -> Maybe (UnwrappedPlugMsg config model msg)
unwrapPlugMsg opt plugMsg =
    case plugMsg of
        PlugMsg indexPath msg ->
            indexPath
                |> Array.get opt.indexDepth
                |> Maybe.andThen
                    (\index ->
                        Plug.get index opt.pipeline
                            |> Maybe.map (UnwrappedPlugMsg msg indexPath index)
                    )
