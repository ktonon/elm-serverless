module Serverless.Conn
    exposing
        ( Conn
        , config
        , id
        , init
        , isActive
        , isSent
        , jsonEncodedResponse
        , method
        , model
        , pause
        , request
        , respond
        , resume
        , route
        , send
        , updateModel
        , updateResponse
        )

{-| Functions for querying and updating connections.

@docs Conn


## Table of Contents

  - [Processing Application Data](#processing-application-data)
  - [Querying the Request](#querying-the-request)
  - [Responding](#responding)
  - [Waiting for Side-Effects](#waiting-for-side-effects)
  - [Misc](#misc)


## Processing Application Data

Query and update your application specific data.

@docs config, model, updateModel


## Querying the Request

Get details about the HTTP request.

@docs request, id, method, route


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

import Json.Encode
import Serverless.Conn.Body as Body exposing (Body, text)
import Serverless.Conn.Request as Request exposing (Id, Method, Request)
import Serverless.Conn.Response as Response exposing (Response, Status, setBody, setStatus)
import Serverless.Port as Port


{-| A connection with a request and response.

Connections are parameterized with config and model record types which are
specific to the application. Config is loaded once on app startup, while model
is set to a provided initial value for each incomming request.

-}
type Conn config model route
    = Conn (Impl config model route)


type alias Impl config model route =
    { pipelineState : PipelineState
    , config : config
    , req : Request
    , resp : Sendable Response
    , model : model
    , route : route
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
config : Conn config model route -> config
config (Conn { config }) =
    config


{-| Application defined model
-}
model : Conn config model route -> model
model (Conn { model }) =
    model


{-| Transform and update the application defined model stored in the connection.
-}
updateModel : (model -> model) -> Conn config model route -> Conn config model route
updateModel update (Conn conn) =
    Conn { conn | model = update conn.model }



-- QUERYING THE REQUEST


{-| Request
-}
request : Conn config model route -> Request
request (Conn { req }) =
    req


{-| Universally unique Conn identifier
-}
id : Conn config model route -> Id
id =
    request >> Request.id


{-| Request HTTP method
-}
method : Conn config model route -> Method
method =
    request >> Request.method


{-| Parsed route
-}
route : Conn config model route -> route
route (Conn { route }) =
    route



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
    -> Conn config model route
    -> ( Conn config model route, Cmd msg )
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
    -> Conn config model route
    -> Conn config model route
updateResponse updater (Conn conn) =
    Conn <|
        case conn.resp of
            Unsent resp ->
                { conn | resp = Unsent (updater resp) }

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
    -> Conn config model route
    -> ( Conn config model route, Cmd msg )
send port_ (Conn conn) =
    case conn.resp of
        Unsent resp ->
            let
                encodedValue =
                    Response.encode (Request.id conn.req) resp
            in
            ( Conn { conn | resp = Sent encodedValue }
            , port_ encodedValue
            )

        Sent _ ->
            ( Conn conn
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
    -> Conn config model route
    -> ( Conn config model route, Cmd msg )
pause i cmd (Conn conn) =
    if i < 0 then
        Debug.crash "pause pipeline called with negative value"
    else
        ( case conn.pipelineState of
            Processing ->
                case i of
                    0 ->
                        Conn conn

                    _ ->
                        Conn { conn | pipelineState = Paused i }

            Paused j ->
                Conn { conn | pipelineState = Paused (i + j) }
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

**NOTE**: It is up to you to make sure your pause count reflects the number of
side-effects that you will be waiting on. It is up to you to `resume 1` each
time you get the result of a side-effect.

An internal server error will occur if the pause count goes below zero.
A resume increment of zero will have no effect.

-}
resume :
    Int
    -> Conn config model route
    -> ( Conn config model route, Cmd msg )
resume i (Conn conn) =
    if i < 0 then
        Debug.crash "resume pipeline called with negative value"
    else
        case conn.pipelineState of
            Processing ->
                case i of
                    0 ->
                        ( Conn conn, Cmd.none )

                    _ ->
                        Debug.crash "resume pipeline called, but processing was not paused"

            Paused j ->
                if j - i > 0 then
                    ( Conn { conn | pipelineState = Paused (j - i) }, Cmd.none )
                else if j - i == 0 then
                    ( Conn { conn | pipelineState = Processing }, Cmd.none )
                else
                    Debug.crash "resume pipeline underflow"



-- MISC


{-| Initialize a new Conn.
-}
init : config -> model -> route -> Request -> Conn config model route
init config model route req =
    Conn
        (Impl Processing
            config
            req
            (Unsent Response.init)
            model
            route
        )


{-| Response as JSON encoded to a string.

This is the format the response takes when it gets sent through the response port.

-}
jsonEncodedResponse : Conn config model route -> String
jsonEncodedResponse (Conn { req, resp }) =
    Json.Encode.encode 0 <|
        case resp of
            Unsent resp ->
                Response.encode (Request.id req) resp

            Sent encodedValue ->
                encodedValue


{-| Is the connnection active?

An active connection is not paused, and has not yet been sent.

-}
isActive : Conn config model route -> Bool
isActive (Conn { resp, pipelineState }) =
    case ( resp, pipelineState ) of
        ( Unsent _, Processing ) ->
            True

        _ ->
            False


{-| Has the response already been sent?
-}
isSent : Conn config model route -> Bool
isSent (Conn { resp }) =
    case resp of
        Sent _ ->
            True

        _ ->
            False
