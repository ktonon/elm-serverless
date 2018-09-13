module Serverless.Conn exposing
    ( Conn, Id
    , config, model, updateModel
    , request, id, method, header, route
    , respond, updateResponse, send, toSent, unsent, mapUnsent
    , textBody, jsonBody, binaryBody
    , interop
    , init, jsonEncodedResponse, interopCalls, interopClear
    )

{-| Functions for querying and updating connections.

@docs Conn, Id


## Table of Contents

  - [Processing Application Data](#processing-application-data)
  - [Querying the Request](#querying-the-request)
  - [Responding](#responding)
  - [Response Body](#response-body)
  - [JavaScript Interop](#javascript-interop)


## Processing Application Data

Query and update your application specific data.

@docs config, model, updateModel


## Querying the Request

Get details about the HTTP request.

@docs request, id, method, header, route


## Responding

Update the response and send it.

@docs respond, updateResponse, send, toSent, unsent, mapUnsent


## Response Body

Use these constructors to create response bodies with different content types.

@docs textBody, jsonBody, binaryBody


## JavaScript Interop

@docs interop


## Misc

These functions are typically not needed when building an application. They are
used internally by the framework. They are useful when debugging or writing unit
tests.

@docs init, jsonEncodedResponse, interopCalls, interopClear

-}

import Json.Encode
import Serverless.Conn.Body as Body exposing (Body)
import Serverless.Conn.Request as Request exposing (Method, Request)
import Serverless.Conn.Response as Response exposing (Response, Status, setBody, setStatus)


{-| A connection with a request and response.

Connections are parameterized with config and model record types which are
specific to the application. Config is loaded once on app startup, while model
is set to a provided initial value for each incomming request.

-}
type Conn config model route interop
    = Conn (Impl config model route interop)


{-| Universally unique connection identifier.
-}
type alias Id =
    String


type alias Impl config model route interop =
    { id : Id
    , config : config
    , req : Request
    , resp : Sendable Response
    , model : model
    , route : route
    , interopCalls : List interop
    }


type Sendable a
    = Unsent a
    | Sent Json.Encode.Value



-- PROCESSING APPLICATION DATA


{-| Application defined configuration
-}
config : Conn config model route interop -> config
config (Conn { config }) =
    config


{-| Application defined model
-}
model : Conn config model route interop -> model
model (Conn { model }) =
    model


{-| Transform and update the application defined model stored in the connection.
-}
updateModel : (model -> model) -> Conn config model route interop -> Conn config model route interop
updateModel update (Conn conn) =
    Conn { conn | model = update conn.model }



-- QUERYING THE REQUEST


{-| Request
-}
request : Conn config model route interop -> Request
request (Conn { req }) =
    req


{-| Get a request header by name
-}
header : String -> Conn config model route interop -> Maybe String
header key (Conn { req }) =
    Request.header key req


{-| Request HTTP method
-}
method : Conn config model route interop -> Method
method =
    request >> Request.method


{-| Parsed route
-}
route : Conn config model route interop -> route
route (Conn { route }) =
    route



-- RESPONDING


{-| Update a response and send it.

    import Serverless.Conn.Response exposing (setBody, setStatus)
    import TestHelpers exposing (conn, responsePort)

    -- The following two expressions produce the same result
    conn
        |> respond ( 200, textBody "Ok" )
    --> conn
    -->     |> updateResponse
    -->         ((setStatus 200) >> (setBody <| textBody "Ok"))
    -->     |> send

-}
respond :
    ( Status, Body )
    -> Conn config model route interop
    -> ( Conn config model route interop, Cmd msg )
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
    -> Conn config model route interop
    -> Conn config model route interop
updateResponse updater (Conn conn) =
    Conn <|
        case conn.resp of
            Unsent resp ->
                { conn | resp = Unsent (updater resp) }

            Sent _ ->
                conn


{-| Sends a connection response through the given port
-}
send :
    Conn config model route interop
    -> ( Conn config model route interop, Cmd msg )
send conn =
    ( toSent conn, Cmd.none )


{-| Converts a conn to a sent conn, making it immutable.

The connection will be sent once the current update loop completes. This
function is intended to be used by middleware, which cannot issue side-effects.

    import TestHelpers exposing (conn)

    (unsent conn) == Just conn
    --> True

    (unsent <| toSent conn) == Nothing
    --> True

-}
toSent :
    Conn config model route interop
    -> Conn config model route interop
toSent (Conn conn) =
    case conn.resp of
        Unsent resp ->
            Conn
                { conn | resp = Sent <| Response.encode resp }

        Sent _ ->
            Conn conn


{-| Return `Just` the same can if it has not been sent yet.
-}
unsent : Conn config model route interop -> Maybe (Conn config model route interop)
unsent (Conn conn) =
    case conn.resp of
        Sent _ ->
            Nothing

        Unsent _ ->
            Just <| Conn conn


{-| Apply an update function to a conn, but only if the conn is unsent.
-}
mapUnsent :
    (Conn config model route interop -> ( Conn config model route interop, Cmd msg ))
    -> Conn config model route interop
    -> ( Conn config model route interop, Cmd msg )
mapUnsent func (Conn conn) =
    case conn.resp of
        Sent _ ->
            ( Conn conn, Cmd.none )

        Unsent _ ->
            func (Conn conn)



-- BODY


{-| A plain text body.
-}
textBody : String -> Body
textBody =
    Body.text


{-| A JSON body.
-}
jsonBody : Json.Encode.Value -> Body
jsonBody =
    Body.json


{-| A binary file.
-}
binaryBody : String -> String -> Body
binaryBody =
    Body.binary



-- JAVASCRIPT INTEROP


{-| Schedule one or more interop calls.
-}
interop :
    List interop
    -> Conn config model route interop
    -> ( Conn config model route interop, Cmd msg )
interop interopCalls (Conn conn) =
    ( Conn { conn | interopCalls = List.append conn.interopCalls interopCalls }
    , Cmd.none
    )


{-| Get all schedule interop calls.
-}
interopCalls : Conn config model route interop -> List interop
interopCalls (Conn { interopCalls }) =
    interopCalls


{-| Remove all schedule interop calls.
-}
interopClear : Conn config model route interop -> Conn config model route interop
interopClear (Conn conn) =
    Conn { conn | interopCalls = [] }



-- MISC


{-| Universally unique Conn identifier
-}
id : Conn config model route interop -> Id
id (Conn { id }) =
    id


{-| Initialize a new Conn.
-}
init : Id -> config -> model -> route -> Request -> Conn config model route interop
init id config model route req =
    Conn
        (Impl
            id
            config
            req
            (Unsent Response.init)
            model
            route
            []
        )


{-| Response as JSON encoded to a string.

This is the format the response takes when it gets sent through the response port.

-}
jsonEncodedResponse : Conn config model route interop -> Json.Encode.Value
jsonEncodedResponse (Conn { resp }) =
    case resp of
        Unsent resp ->
            Response.encode resp

        Sent encodedValue ->
            encodedValue
