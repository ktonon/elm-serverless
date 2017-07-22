module Serverless.TestTypes exposing (..)

import Json.Encode as J
import Serverless.Types as Types


type alias Config =
    { secret : String
    }


type alias Model =
    { counter : Int
    }


type Msg
    = NoOp


type alias Plug =
    Types.Plug Config Model Msg


type alias Conn =
    Types.Conn Config Model


type alias RequestPort msg =
    Types.RequestPort msg


type alias ResponsePort msg =
    Types.ResponsePort msg


requestPort : (J.Value -> msg) -> Sub msg
requestPort _ =
    Sub.none


responsePort : J.Value -> Cmd msg
responsePort _ =
    -- We don't use Cmd.none because some tests compare values sent to the
    -- response port to Cmd.none, to make sure something was actually sent
    Cmd.batch [ Cmd.none ]
