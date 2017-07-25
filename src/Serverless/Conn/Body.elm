module Serverless.Conn.Body
    exposing
        ( Body
        , appendText
        , contentType
        , decoder
        , empty
        , encode
        , isEmpty
        , json
        , text
        )

{-| Request/response body with functions to query and update.

@docs Body

## Constructors

@docs empty, text, json

## Querying

@docs contentType, isEmpty

## Updating

@docs appendText

## Misc

These functions are typically not needed when building an application. They are
used internally by the framework.

@docs decoder, encode
-}

import Json.Decode as Decode exposing (Decoder, andThen)
import Json.Encode as Encode


{-| Request or response body.
-}
type Body
    = Empty
    | Text String
    | Json Encode.Value



-- CONSTRUCTORS


{-| An empty body.

Represents the lack of a request or response body.
-}
empty : Body
empty =
    Empty


{-| A plain text body.
-}
text : String -> Body
text =
    Text


{-| A JSON body.
-}
json : Encode.Value -> Body
json =
    Json



-- QUERY


{-| The content type of a given body.

    import Json.Encode

    contentType (text "hello")
    --> "text/text"

    contentType (json Json.Encode.null)
    --> "application/json"
-}
contentType : Body -> String
contentType body =
    case body of
        Json _ ->
            "application/json"

        _ ->
            "text/text"


{-| Is the given body empty?

    import Json.Encode exposing (list)

    isEmpty (empty)
    --> True

    isEmpty (text "")
    --> False

    isEmpty (json (list []))
    --> False
-}
isEmpty : Body -> Bool
isEmpty body =
    case body of
        Empty ->
            True

        _ ->
            False



-- UPDATE


{-| Appends text to a given body if possible.

    import Json.Encode exposing (list)

    text "foo" |> appendText "bar"
    --> Ok (text "foobar")

    empty |> appendText "to empty"
    --> Ok (text "to empty")

    json (list []) |> appendText "will fail"
    --> Err "cannot append text to json"
-}
appendText : String -> Body -> Result String Body
appendText val body =
    case body of
        Empty ->
            Ok (Text val)

        Text existingVal ->
            Ok (Text (existingVal ++ val))

        Json jval ->
            Err "cannot append text to json"



-- JSON


{-| JSON decoder a request body.
-}
decoder : Decoder Body
decoder =
    Decode.nullable Decode.string
        |> andThen
            ((Maybe.map Text)
                >> (Maybe.withDefault Empty)
                >> Decode.succeed
            )


{-| JSON encode a response body.
-}
encode : Body -> Encode.Value
encode body =
    case body of
        Empty ->
            Encode.null

        Text w ->
            Encode.string w

        Json j ->
            j
