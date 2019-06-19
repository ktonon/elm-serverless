module Quoted.Pipelines.Quote exposing (gotQuotes, langFilter, loadQuotes, router)

import Http
import Quoted.Models.Quote as Quote
import Quoted.Route exposing (..)
import Quoted.Types exposing (Conn, Msg(..), responsePort)
import Serverless.Conn as Conn exposing (jsonBody, method, respond, textBody, updateResponse)
import Serverless.Conn.Request as Request exposing (Method(..))
import Task


router : Lang -> Conn -> ( Conn, Cmd Msg )
router lang conn =
    case method conn of
        GET ->
            loadQuotes lang conn

        POST ->
            respond
                ( 501
                , textBody <|
                    "Not implemented, but I got this body: "
                  --  ++ (conn |> Conn.request |> Request.body |> toString)
                )
                conn

        _ ->
            respond ( 405, textBody "Method not allowed" ) conn


loadQuotes : Quoted.Route.Lang -> Conn -> ( Conn, Cmd Msg )
loadQuotes lang conn =
    case
        conn
            |> Conn.config
            |> .languages
            |> langFilter lang
    of
        [] ->
            respond ( 404, textBody "Could not find language" ) conn

        langs ->
            ( conn
            , -- A response does not need to be sent immediately.
              -- Here we make a request to another service...
              langs
                |> List.map Quote.request
                |> List.map Http.toTask
                |> Task.sequence
                |> Task.attempt GotQuotes
            )


gotQuotes : Result Http.Error (List Quoted.Types.Quote) -> Conn -> ( Conn, Cmd Msg )
gotQuotes result conn =
    case result of
        Ok q ->
            -- ...and send our response once we have the results
            respond
                ( 200
                , q
                    |> List.sortBy .lang
                    |> Quote.encodeList
                    |> jsonBody
                )
                conn

        Err err ->
            --respond ( 500, textBody <| toString err ) conn
            respond ( 500, textBody <| "HTTP Error" ) conn



-- HELPERS


langFilter : Quoted.Route.Lang -> List String -> List String
langFilter filt langs =
    case filt of
        LangAll ->
            langs

        Lang string ->
            if langs |> List.member string then
                [ string ]

            else
                []
