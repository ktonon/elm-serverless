module Custom exposing (..)

import Serverless.Conn.Types as Types


type alias Conn =
    Types.Conn Config Model Route


type alias Config =
    { secret : String
    }


type alias Model =
    { counter : Int
    }


type Route
    = NotFound
