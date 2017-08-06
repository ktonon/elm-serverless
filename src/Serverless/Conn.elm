module Serverless.Conn
    exposing
        ( Conn
        , config
        , header
        , id
        , init
        , jsonEncodedResponse
        , mapUnsent
        , method
        , model
        , request
        , respond
        , route
        , send
        , unsent
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

@docs request, id, method, header, route


## Responding

Update the response and send it.

@docs respond, updateResponse, send, unsent, mapUnsent


## Misc

These functions are typically not needed when building an application. They are
used internally by the framework. They are useful when debugging or writing unit
tests.

@docs init, jsonEncodedResponse

-}

import Json.Encode
import Serverless.Conn.Body as Body exposing (Body, text)
import Serverless.Conn.Request as Request exposing (Id, Method, Request)
import Serverless.Conn.Response as Response exposing (Response, Status, setBody, setStatus)


{-| A connection with a request and response.

Connections are parameterized with config and model record types which are
specific to the application. Config is loaded once on app startup, while model
is set to a provided initial value for each incomming request.

-}
type Conn config model route
    = Conn (Impl config model route)


type alias Impl config model route =
    { config : config
    , req : Request
    , resp : Sendable Response
    , model : model
    , route : route
    }


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


{-| Get a request header by name
-}
header : String -> Conn config model route -> Maybe String
header key (Conn { req }) =
    Request.header key req


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
        |> respond ( 200, text "Ok" )
    --> conn
    -->     |> updateResponse
    -->         ((setStatus 200) >> (setBody <| text "Ok"))
    -->     |> send

-}
respond :
    ( Status, Body )
    -> Conn config model route
    -> Conn config model route
respond ( status, body ) =
    updateResponse
        (setStatus status >> setBody body)
        >> send


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

    import TestHelpers exposing (conn)

    (unsent conn) == Just conn
    --> True

    (unsent <| send conn) == Nothing
    --> True

-}
send :
    Conn config model route
    -> Conn config model route
send (Conn conn) =
    case conn.resp of
        Unsent resp ->
            Conn
                { conn
                    | resp =
                        Sent <| Response.encode (Request.id conn.req) resp
                }

        Sent _ ->
            Conn conn


{-| Return `Just` the same can if it has not been sent yet.
-}
unsent : Conn config model route -> Maybe (Conn config model route)
unsent (Conn conn) =
    case conn.resp of
        Sent _ ->
            Nothing

        Unsent _ ->
            Just <| Conn conn


{-| Apply an update function to a conn, but only if the conn is unsent.
-}
mapUnsent :
    (Conn config model route -> ( Conn config model route, Cmd msg ))
    -> Conn config model route
    -> ( Conn config model route, Cmd msg )
mapUnsent func (Conn conn) =
    case conn.resp of
        Sent _ ->
            ( Conn conn, Cmd.none )

        Unsent _ ->
            func (Conn conn)



-- MISC


{-| Initialize a new Conn.
-}
init : config -> model -> route -> Request -> Conn config model route
init config model route req =
    Conn
        (Impl
            config
            req
            (Unsent Response.init)
            model
            route
        )


{-| Response as JSON encoded to a string.

This is the format the response takes when it gets sent through the response port.

-}
jsonEncodedResponse : Conn config model route -> Json.Encode.Value
jsonEncodedResponse (Conn { req, resp }) =
    case resp of
        Unsent resp ->
            Response.encode (Request.id req) resp

        Sent encodedValue ->
            encodedValue
