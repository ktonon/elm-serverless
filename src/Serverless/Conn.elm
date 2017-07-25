module Serverless.Conn
    exposing
        ( Conn
        , config
        , id
        , init
        , isActive
        , isSent
        , method
        , model
        , parseRoute
        , path
        , pause
        , resume
        , request
        , respond
        , jsonEncodedResponse
        , send
        , updateModel
        , updateResponse
        )

{-| Functions for querying and updating connections.

@docs Conn

## Table of Contents

* [Processing Application Data](#processing-application-data)
* [Querying the Request](#querying-the-request)
* [Responding](#responding)
* [Waiting for Side-Effects](#waiting-for-side-effects)
* [Misc](#misc)

## Processing Application Data

Query and update your application specific data.

@docs config, model, updateModel

## Querying the Request

Get details about the HTTP request.

@docs request, id, method, path, parseRoute

## Responding

Update the response and send it.

@docs respond, updateResponse, send

## Waiting for Side-Effects

Use inside a loop plug which needs to wait for the results of a side effect.

@docs pause, resume

## Misc

These functions are typically not needed when building an application. They are
used internally by the framework. They are useful when debugging or writing unit
tests.

@docs init, jsonEncodedResponse, isActive, isSent
-}

import Dict
import Json.Encode
import Serverless.Conn.Body as Body exposing (Body, text)
import Serverless.Conn.Request as Request exposing (Id, Method, Request)
import Serverless.Conn.Response as Response exposing (Response, Status, setBody, setStatus)
import Serverless.Port as Port
import UrlParser


{-| A connection with a request and response.

Connections are parameterized with config and model record types which are
specific to the application. Config is loaded once on app startup, while model
is set to a provided initial value for each incomming request.
-}
type Conn config model
    = Conn (Impl config model)


get : (Impl config model -> a) -> Conn config model -> a
get getter conn =
    case conn of
        Conn impl ->
            getter impl


type alias Impl config model =
    { pipelineState : PipelineState
    , config : config
    , req : Request
    , resp : Sendable Response
    , model : model
    }


type PipelineState
    = Processing
    | Paused Int


type Sendable a
    = Unsent a
    | Sent Json.Encode.Value



-- PROCESSING APPLICATION DATA


{-| Application defined configuration
-}
config : Conn config model -> config
config =
    get .config


{-| Application defined model
-}
model : Conn config model -> model
model =
    get .model


{-| Transform and update the application defined model stored in the connection.
-}
updateModel : (model -> model) -> Conn config model -> Conn config model
updateModel update conn =
    case conn of
        Conn impl ->
            Conn { impl | model = update impl.model }



-- QUERYING THE REQUEST


{-| Request
-}
request : Conn config model -> Request
request =
    get .req


{-| Universally unique Conn identifier
-}
id : Conn config model -> Id
id =
    request >> Request.id


{-| Request HTTP method
-}
method : Conn config model -> Method
method =
    request >> Request.method


{-| Request path
-}
path : Conn config model -> String
path =
    request >> Request.path


{-| Parse a connection request path into nicely formatted elm data.

    import UrlParser exposing (Parser, (</>), s, int, top, map, oneOf)

    route : Parser (List String -> a) a
    route =
        oneOf
            [ map ["home"] top
            , map
                (\n -> List.repeat n "yay")
                (s "cheers" </> int)
            ]

    "/" |> parseRoute route ["not found"]
    --> ["home"]

    "/cheers/3" |> parseRoute route ["not found"]
    --> ["yay", "yay", "yay"]

    "/beers" |> parseRoute route ["not found"]
    --> ["not found"]
-}
parseRoute : UrlParser.Parser (route -> route) route -> route -> String -> route
parseRoute router defaultRoute path =
    UrlParser.parse router path Dict.empty
        |> Maybe.withDefault defaultRoute



-- RESPONDING


{-| Update a response and send it.

    import Serverless.Conn.Body exposing (text)
    import Serverless.Conn.Response exposing (setBody, setStatus)
    import TestHelpers exposing (conn, responsePort)

    -- The following two expressions produce the same result
    conn
        |> respond responsePort ( 200, text "Ok" )
    --> conn
    -->     |> updateResponse
    -->         ((setStatus 200) >> (setBody <| text "Ok"))
    -->     |> send responsePort
-}
respond :
    Port.Response msg
    -> ( Status, Body )
    -> Conn config model
    -> ( Conn config model, Cmd msg )
respond port_ ( status, body ) =
    updateResponse
        (setStatus status >> setBody body)
        >> send port_


{-| Applies the given transformation to the connection response.

Does not do anything if the response has already been sent.

    import Serverless.Conn.Response exposing (addHeader)
    import TestHelpers exposing (conn, getHeader)

    conn
        |> updateResponse
            (addHeader ( "Cache-Control", "no-cache" ))
        |> getHeader "cache-control"
    --> Just "no-cache"
-}
updateResponse :
    (Response -> Response)
    -> Conn config model
    -> Conn config model
updateResponse updater conn =
    case conn of
        Conn impl ->
            case impl.resp of
                Unsent resp ->
                    Conn { impl | resp = Unsent (updater resp) }

                Sent _ ->
                    conn


{-| Sends a connection response through the given port

    import TestHelpers exposing (conn, responsePort)

    conn
        |> isSent
    --> False

    conn
        |> send responsePort
        |> (Tuple.first >> isSent)
    --> True

    conn
        |> send responsePort
        |> (Tuple.second >> (==) Cmd.none)
    --> False
-}
send :
    Port.Response msg
    -> Conn config model
    -> ( Conn config model, Cmd msg )
send port_ conn =
    case conn of
        Conn impl ->
            case impl.resp of
                Unsent resp ->
                    let
                        encodedValue =
                            Response.encode (id conn) resp
                    in
                        ( Conn { impl | resp = Sent encodedValue }
                        , port_ encodedValue
                        )

                Sent _ ->
                    ( conn
                    , Cmd.none
                    )



-- WAITING FOR SIDE-EFFECTS


{-| Pause the connection at the current loop plug.

Increments the pause count by the amount given. You will need to resume by the
same amount for pipeline processing to continue onto the next plug.

    import TestHelpers exposing (conn, httpGet)

    conn
        |> isActive
    --> True

    conn
        |> pause 1 (httpGet "some/thing" "My Handler")
        |> (Tuple.first >> isActive)
    --> False

An internal server error occure if the pause increment is negative.
A pause increment of zero will have no effect.
-}
pause :
    Int
    -> Cmd msg
    -> Conn config model
    -> ( Conn config model, Cmd msg )
pause i cmd conn =
    if i < 0 then
        Debug.crash "pause pipeline called with negative value"
    else
        case conn of
            Conn impl ->
                ( case impl.pipelineState of
                    Processing ->
                        case i of
                            0 ->
                                conn

                            _ ->
                                Conn { impl | pipelineState = Paused i }

                    Paused j ->
                        Conn { impl | pipelineState = Paused (i + j) }
                , cmd
                )


{-| Resume pipeline processing.

Decrements the pause count by the amount given. You should only call this after
a call to pause, and should decrement it by the same amount. It is ok to make
multiple calls, as long as the sum of pauses equals the sum of resumes.

    import TestHelpers exposing (conn, httpGet)

    conn
        |> pause 2
            (Cmd.batch
                [ httpGet "some/thing" "My Handler"
                , httpGet "some/other" "My Handler"
                ]
            )
        |> (Tuple.first >> resume 1)
        |> (Tuple.first >> resume 1)
        |> (Tuple.first >> isActive)
    --> True

The above example shows how balancing the pause and resume counts makes the
connection active again. In reality, pause and resume would be asynchronous.

__NOTE__: It is up to you to make sure your pause count reflects the number of
side-effects that you will be waiting on. It is up to you to `resume 1` each
time you get the result of a side-effect.

An internal server error will occur if the pause count goes below zero.
A resume increment of zero will have no effect.
-}
resume :
    Int
    -> Conn config model
    -> ( Conn config model, Cmd msg )
resume i conn =
    if i < 0 then
        Debug.crash "resume pipeline called with negative value"
    else
        case conn of
            Conn impl ->
                case impl.pipelineState of
                    Processing ->
                        case i of
                            0 ->
                                ( conn, Cmd.none )

                            _ ->
                                Debug.crash "resume pipeline called, but processing was not paused"

                    Paused j ->
                        if j - i > 0 then
                            ( Conn { impl | pipelineState = Paused (j - i) }, Cmd.none )
                        else if j - i == 0 then
                            ( Conn { impl | pipelineState = Processing }, Cmd.none )
                        else
                            Debug.crash "resume pipeline underflow"



-- MISC


{-| Initialize a new Conn.
-}
init : config -> model -> Request -> Conn config model
init config model req =
    Conn
        (Impl Processing
            config
            req
            (Unsent Response.init)
            model
        )


{-| Response as JSON encoded to a string.

This is the format the response takes when it gets sent through the response port.
-}
jsonEncodedResponse : Conn config model -> String
jsonEncodedResponse conn =
    Json.Encode.encode 0 <|
        case get .resp conn of
            Unsent resp ->
                Response.encode (id conn) resp

            Sent encodedValue ->
                encodedValue


{-| Is the connnection active?

An active connection is not paused, and has not yet been sent.
-}
isActive : Conn config mode -> Bool
isActive conn =
    case conn of
        Conn impl ->
            case ( impl.resp, impl.pipelineState ) of
                ( Unsent _, Processing ) ->
                    True

                _ ->
                    False


{-| Has the response already been sent?
-}
isSent : Conn config model -> Bool
isSent conn =
    case conn of
        Conn { resp } ->
            case resp of
                Sent _ ->
                    True

                _ ->
                    False
