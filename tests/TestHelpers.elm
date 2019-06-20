module TestHelpers exposing (Config, Conn, Model, Msg(..), Plug, Route(..), appendToBody, conn, getHeader, httpGet, requestPort, responsePort, route, simpleLoop, simplePlug)

import Json.Encode as Encode
import Regex
import Serverless.Conn as Conn exposing (updateResponse)
import Serverless.Conn.Body as Body exposing (appendText)
import Serverless.Conn.Request as Request exposing (Request)
import Serverless.Conn.Response as Response exposing (Response, updateBody)
import Serverless.Plug as Plug exposing (pipeline, plug)
import Url.Parser exposing ((</>), Parser, map, oneOf, s, string, top)


appendToBody : String -> Conn -> Conn
appendToBody x conn_ =
    updateResponse
        (updateBody
            (\body ->
                case appendText x body of
                    Ok newBody ->
                        newBody

                    Err err ->
                        Debug.todo "crash"
            )
        )
        conn_


simplePlug : String -> Conn -> Conn
simplePlug =
    appendToBody


simpleLoop : String -> Msg -> Conn -> ( Conn, Cmd Msg )
simpleLoop label msg conn_ =
    ( conn_ |> appendToBody label, Cmd.none )



-- ROUTING


type Route
    = Home
    | Foody String
    | NoCanFind


route : Parser (Route -> a) a
route =
    oneOf
        [ map Home top
        , map Foody (s "foody" </> string)
        ]



-- DOC TESTS


conn : Conn
conn =
    Conn.init "id" (Config "secret") (Model 0) Home Request.init


getHeader : String -> Conn -> Maybe String
getHeader key conn_ =
    conn_
        |> Conn.jsonEncodedResponse
        |> Encode.encode 0
        |> Regex.findAtMost 1 (Maybe.withDefault Regex.never <| Regex.fromString <| "\"" ++ key ++ "\":\"(.*?)\"")
        |> List.head
        |> Maybe.andThen (\{ submatches } -> List.head submatches)
        |> Maybe.andThen (\x -> x)


httpGet : String -> a -> Cmd msg
httpGet _ _ =
    Cmd.none



-- TYPES


type alias Config =
    { secret : String
    }


type alias Model =
    { counter : Int
    }


type Msg
    = NoOp


type alias Plug =
    Plug.Plug Config Model Route


type alias Conn =
    Conn.Conn Config Model Route


requestPort : (Encode.Value -> msg) -> Sub msg
requestPort _ =
    Sub.none


responsePort : Encode.Value -> Cmd msg
responsePort _ =
    -- We don't use Cmd.none because some tests compare values sent to the
    -- response port to Cmd.none, to make sure something was actually sent
    Cmd.batch [ Cmd.none ]
