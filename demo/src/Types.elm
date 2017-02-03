port module Types exposing (..)

import Http
import Json.Decode exposing (Decoder, list, string)
import Json.Decode.Pipeline exposing (required, decode, hardcoded)
import Serverless.Cors as Cors
import Serverless.Types as Types


-- CUSTOM TYPES
--
-- The following (Config, Model, and Msg) are required by Serverless.Program,
-- but can be defined as anything you want.


{-| Can be anything you want, you just need to provide a decoder
-}
type alias Config =
    { languages : List String
    , cors : Cors.Config
    }


configDecoder : Json.Decode.Decoder Config
configDecoder =
    decode Config
        |> required "languages" (list string)
        |> required "cors" Cors.configDecoder


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
    | QuoteResult (Result Http.Error Quote)



-- SERVERLESS TYPES
--
-- Provide concrete values for the type variable defined in Serverless.Types
-- then import this module instead, to make your code more readable.


type alias Plug =
    Types.Plug Config Model Msg


type alias Conn =
    Types.Conn Config Model


type alias RequestPort msg =
    Types.RequestPort msg


type alias ResponsePort msg =
    Types.ResponsePort msg


port requestPort : RequestPort msg


port responsePort : ResponsePort msg
