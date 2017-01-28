module Serverless.Conn.Pool exposing (..)

import Dict exposing (Dict)
import Serverless.Conn.Types exposing (..)
import Serverless.Conn.Private exposing (initResponse)


type alias Pool config model route =
    { conn : Dict Id (Conn config model route)
    , initialModel : model
    , config : Maybe config
    }


empty : model -> Maybe config -> Pool config model route
empty =
    Pool Dict.empty


add : Request -> Pool config model route -> Pool config model route
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
                        Nothing
                    )

        _ ->
            Debug.log "Failed to add request! Pool has no config" pool


get : Id -> Pool config model route -> Maybe (Conn config model route)
get requestId pool =
    pool.conn |> Dict.get requestId


replace :
    Conn config model route
    -> Pool config model route
    -> Pool config model route
replace conn pool =
    let
        newConn =
            pool.conn |> Dict.insert conn.req.id conn
    in
        { pool | conn = newConn }


connections : Pool config model route -> List (Conn config model route)
connections pool =
    pool.conn |> Dict.values
