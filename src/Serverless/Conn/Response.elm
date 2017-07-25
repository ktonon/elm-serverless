module Serverless.Conn.Response
    exposing
        ( Response
        , Status
        , addHeader
        , setBody
        , updateBody
        , setStatus
        , init
        , encode
        )

{-| Query and update the HTTP response.

@docs Response, Status

## Updating

@docs addHeader, setBody, updateBody, setStatus

## Misc

These functions are typically not needed when building an application. They are
used internally by the framework. They are useful when debugging or writing unit
tests.

@docs init, encode
-}

import Json.Encode as Encode
import Serverless.Conn.Body as Body exposing (Body, text)
import Serverless.Conn.Charset as Charset exposing (Charset)
import Serverless.Conn.Request exposing (Id)
import Serverless.Conn.KeyValueList as KeyValueList


{-| An HTTP response.
-}
type Response
    = Response Model


type alias Model =
    { body : Body
    , charset : Charset
    , headers : List ( String, String )
    , status : Status
    }


{-| An HTTP status code.
-}
type alias Status =
    Int



-- UPDATING


update : (Model -> Model) -> Response -> Response
update update resp =
    case resp of
        Response model ->
            Response (update model)


{-| Set a response header.

If you set the same response header more than once, the second value will
override the first.
-}
addHeader : ( String, String ) -> Response -> Response
addHeader ( key, value ) =
    update
        (\model ->
            { model
                | headers =
                    ( key |> String.toLower, value )
                        :: model.headers
            }
        )


{-| Set the response body.
-}
setBody : Body -> Response -> Response
setBody body =
    update
        (\model ->
            { model
                | body = body
            }
        )


{-| Updates the response body.
-}
updateBody : (Body -> Body) -> Response -> Response
updateBody updater =
    update (\model -> { model | body = updater model.body })


setCharset : Charset -> Response -> Response
setCharset value =
    update (\model -> { model | charset = value })


{-| Set the response HTTP status code.
-}
setStatus : Status -> Response -> Response
setStatus value =
    update (\model -> { model | status = value })



-- MISC


{-| A response with an empty body and invalid status.
-}
init : Response
init =
    Response
        (Model
            Body.empty
            Charset.utf8
            [ ( "cache-control", "max-age=0, private, must-revalidate" ) ]
            200
        )


{-| JSON encode an HTTP response.
-}
encode : Id -> Response -> Encode.Value
encode id res =
    case res of
        Response model ->
            Encode.object
                [ ( "id", Encode.string id )
                , ( "body", Body.encode model.body )
                , ( "headers"
                  , model.headers
                        ++ [ ( "content-type", contentType model ) ]
                        |> KeyValueList.encode
                  )
                , ( "statusCode", Encode.int model.status )
                ]


contentType : Model -> String
contentType { body, charset } =
    Body.contentType body
        ++ "; charset="
        ++ (Charset.toString charset)
