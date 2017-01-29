module Pipelines.Quote exposing (..)

import Http
import Models.Quote exposing (..)
import Route exposing (..)
import Serverless.Conn exposing (..)
import Serverless.Conn.Types exposing (..)
import Serverless.Plug as Plug exposing (..)
import Types exposing (..)


pipeline : Lang -> Pipeline
pipeline lang =
    Plug.pipeline
        -- Loop pipelines are like elm update functions.
        -- They can be used to wait for the results of side effects.
        -- For example, loadQuotes makes a few http requests and collects the
        -- results in the model.
        --
        |>
            loop (loadQuotes lang)
        -- You can have multiple loop plugs. The last one in the pipeline
        -- must send a respnose, or an internal server error will automatically
        -- be sent by the framework
        |>
            loop respondWithQuotes


langFilter : Route.Lang -> List String -> List String
langFilter filt langs =
    case filt of
        LangAll ->
            langs

        Lang string ->
            if langs |> List.member string then
                [ string ]
            else
                []


loadQuotes : Route.Lang -> Msg -> Conn -> ( Conn, Cmd Msg )
loadQuotes lang msg conn =
    case msg of
        Endpoint ->
            (case conn.config.languages |> langFilter lang of
                [] ->
                    conn
                        |> status (Code 404)
                        |> body (TextBody "Could not find language")
                        |> send responsePort

                langs ->
                    -- Whenever you return a side effect for which you want to
                    -- wait for the response, you should pause the connection.
                    -- In this case, we are going to wait for X http requests (one
                    -- for each supported language), so we increment the pause count
                    -- by X
                    --
                    -- Pausing the connection prevents the pipeline from continuing
                    -- past this plug. At least, until resume reduces the pause count
                    -- back to zero.
                    conn
                        |> pipelinePause
                            (langs |> List.length)
                            (langs
                                |> List.map quoteRequest
                                |> List.map (Http.send QuoteResult)
                                |> Cmd.batch
                            )
                            responsePort
            )

        QuoteResult result ->
            case result of
                Ok q ->
                    conn
                        |> updateModel (\model -> { model | quotes = q :: model.quotes })
                        -- We've got one of our responses now, so we reduce the
                        -- pause count by 1. When all the responses are collected
                        -- our pause count will be zero, and the pipeline will
                        -- automatically continue onto the next plug.
                        --
                        -- The response port is passed because resume will
                        -- automatically send server errors if the pause count
                        -- underflows.
                        -- Try changing the resume count to 3, to see what happens
                        |>
                            pipelineResume 1 responsePort

                Err err ->
                    -- If anything unexpected happends, we can always send a
                    -- response early. Sending a response prevents further plugs
                    -- from processing and removes the connection from the
                    -- connection pool
                    conn
                        |> internalError (err |> toString |> TextBody) responsePort


respondWithQuotes : Msg -> Conn -> ( Conn, Cmd Msg )
respondWithQuotes msg conn =
    case msg of
        -- Each time a plug is processed for the first time, it will get the
        -- endpoint message.
        Endpoint ->
            conn
                |> status (Code 200)
                |> header ( "content-type", "text/html" )
                -- By the time we get here, we can be sure that loadQuotes has
                -- successfully loaded all the quotes, so we can sort, format,
                -- and send them in the response body.
                |>
                    body
                        (conn.model.quotes
                            |> List.sortBy .lang
                            |> List.map (formatQuote "<br/>")
                            |> String.join "<br/><br/>"
                            |> TextBody
                        )
                |> send responsePort

        -- This method only expects Endpoint. If we get anything else, it means
        -- that something is wrong with our pause/resuming count from the previous
        -- plug.
        _ ->
            conn |> unexpectedMsg msg responsePort
