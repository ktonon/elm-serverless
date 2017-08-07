port module Types exposing (..)

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, hardcoded, required)
import Route exposing (Route)
import Serverless.Conn
import Serverless.Port


-- CUSTOM TYPES
--
-- The following (Config, Model, and Msg) are required by Serverless.Program,
-- but can be defined as anything you want.


{-| Can be anything you want, you just need to provide a decoder
-}
type alias Config =
    { languages : List String
    , enableAuth : Bool
    }


configDecoder : Decoder Config
configDecoder =
    decode Config
        |> required "languages" (Decode.list Decode.string)
        |> required "enableAuth" (Decode.string |> Decode.map ((==) "true"))


{-| Can be anything you want.
This will get set to initialModel (see above) for each incomming connection.
-}
type alias Model =
    { quotes : List Quote
    }


type alias Quote =
    { lang : String
    , text : String
    , author : String
    }


{-| Your custom message type.

The only restriction is that it has to contain an endpoint. You can call the
endpoint whatever you want, but it accepts no parameters, and must be provided
to the program as `endpoint` (see above).

-}
type Msg
    = Endpoint
    | GotQuotes (Result Http.Error (List Quote))



-- SERVERLESS TYPES
--
-- Provide concrete values for the type variable defined in Serverless.Types
-- then import this module instead, to make your code more readable.


type alias Conn =
    Serverless.Conn.Conn Config Model Route


port requestPort : Serverless.Port.Request msg


port responsePort : Serverless.Port.Response msg
