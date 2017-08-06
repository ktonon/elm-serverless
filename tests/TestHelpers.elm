module TestHelpers exposing (..)

import Json.Encode as Encode
import Regex exposing (HowMany(..), regex)
import Serverless.Conn as Conn exposing (updateResponse)
import Serverless.Conn.Body as Body exposing (appendText)
import Serverless.Conn.Request as Request exposing (Request)
import Serverless.Conn.Response as Response exposing (Response, updateBody)
import Serverless.Plug as Plug exposing (pipeline, plug)
import UrlParser exposing ((</>), Parser, map, oneOf, s, string, top)


appendToBody : String -> Conn -> Conn
appendToBody x conn =
    updateResponse
        (updateBody
            (\body ->
                case appendText x body of
                    Ok newBody ->
                        newBody

                    Err err ->
                        Debug.crash err
            )
        )
        conn


simplePlug : String -> Conn -> Conn
simplePlug =
    appendToBody


simpleLoop : String -> Msg -> Conn -> ( Conn, Cmd Msg )
simpleLoop label msg conn =
    ( conn |> appendToBody label, Cmd.none )



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
    Conn.init (Config "secret") (Model 0) Home <| Request.init "id"


getHeader : String -> Conn -> Maybe String
getHeader key conn =
    conn
        |> Conn.jsonEncodedResponse
        |> Encode.encode 0
        |> Regex.find (AtMost 1) (regex <| "\"" ++ key ++ "\":\"(.*?)\"")
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
    Plug.Plug Config Model Route Msg


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
