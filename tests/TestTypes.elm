port module TestTypes exposing (..)

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


port requestPort : RequestPort msg


port responsePort : ResponsePort msg
