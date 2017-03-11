module Serverless.Conn.Response
    exposing
        ( Response
        , Status
        , addHeader
        , encode
        , init
        , setBody
        , setStatus
        , updateBody
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


{-| Set a response header.

If you set the same response header more than once, the second value will
override the first.

-}
addHeader : ( String, String ) -> Response -> Response
addHeader ( key, value ) (Response res) =
    Response
        { res
            | headers =
                ( key |> String.toLower, value )
                    :: res.headers
        }


{-| Set the response body.
-}
setBody : Body -> Response -> Response
setBody body (Response res) =
    Response { res | body = body }


{-| Updates the response body.
-}
updateBody : (Body -> Body) -> Response -> Response
updateBody updater (Response res) =
    Response { res | body = updater res.body }


setCharset : Charset -> Response -> Response
setCharset value (Response res) =
    Response { res | charset = value }


{-| Set the response HTTP status code.
-}
setStatus : Status -> Response -> Response
setStatus value (Response res) =
    Response { res | status = value }



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
encode : Response -> Encode.Value
encode (Response res) =
    Encode.object
        [ ( "body", Body.encode res.body )
        , ( "headers"
          , res.headers
                ++ [ ( "content-type", contentType res ) ]
                |> KeyValueList.encode
          )
        , ( "statusCode", Encode.int res.status )
        ]


contentType : Model -> String
contentType { body, charset } =
    Body.contentType body
        ++ "; charset="
        ++ Charset.toString charset
