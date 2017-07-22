module Serverless.Pool exposing (..)

import Dict exposing (Dict)
import Logging exposing (Logger, LogLevel(..))
import Serverless.Conn.Types exposing (..)
import Serverless.Types exposing (Conn, PipelineState(..), Sendable(..))


-- CONNECTION POOL


type alias Pool config model =
    { conn : Dict Id (Conn config model)
    , initialModel : model
    , config : Maybe config
    }


empty : model -> Maybe config -> Pool config model
empty =
    Pool Dict.empty


add : Logger (Pool config model) -> Request -> Pool config model -> Pool config model
add logger req pool =
    case pool.config of
        Just config ->
            pool
                |> replace
                    (Conn Processing
                        config
                        req
                        initResponse
                        pool.initialModel
                    )

        _ ->
            logger LogError "Failed to add request! Pool has no config" pool


get : Id -> Pool config model -> Maybe (Conn config model)
get requestId pool =
    pool.conn |> Dict.get requestId


replace :
    Conn config model
    -> Pool config model
    -> Pool config model
replace conn pool =
    let
        newConn =
            pool.conn |> Dict.insert conn.req.id conn
    in
        { pool | conn = newConn }


connections : Pool config model -> List (Conn config model)
connections pool =
    pool.conn |> Dict.values


initResponse : Sendable Response
initResponse =
    Unsent
        (Response
            NoBody
            Utf8
            [ ( "cache-control", "max-age=0, private, must-revalidate" ) ]
            InvalidStatus
        )
