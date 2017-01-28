module Serverless.Conn.Pool exposing (..)

import Dict exposing (Dict)
import Serverless.Conn.Types exposing (..)
import Serverless.Conn.Private exposing (initResponse)


type alias Pool config model =
    { conn : Dict Id (Conn config model)
    , initialModel : model
    , config : Maybe config
    }


empty : model -> Maybe config -> Pool config model
empty =
    Pool Dict.empty


add : Request -> Pool config model -> Pool config model
add req pool =
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
            Debug.log "Failed to add request! Pool has no config" pool


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
