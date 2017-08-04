module Serverless.Conn.Pool exposing (..)

import Dict exposing (Dict)
import Logging exposing (LogLevel(..), Logger)
import Serverless.Conn as Conn exposing (Conn)
import Serverless.Conn.Request exposing (Id, Request)


-- CONNECTION POOL


type alias Pool config model route =
    { connDict : Dict Id (Conn config model route)
    , initialModel : model
    , config : Maybe config
    }


empty :
    model
    -> Maybe config
    -> Pool config model route
empty =
    Pool Dict.empty


add :
    Logger (Pool config model route)
    -> route
    -> Request
    -> Pool config model route
    -> Pool config model route
add logger route req pool =
    case pool.config of
        Just config ->
            pool
                |> replace
                    (Conn.init config pool.initialModel route req)

        _ ->
            logger LogError "Failed to add request! Pool has no config" pool


get :
    Id
    -> Pool config model route
    -> Maybe (Conn config model route)
get requestId { connDict } =
    Dict.get requestId connDict


replace :
    Conn config model route
    -> Pool config model route
    -> Pool config model route
replace conn pool =
    let
        newConnDict =
            Dict.insert (Conn.id conn) conn pool.connDict
    in
    { pool | connDict = newConnDict }


connections :
    Pool config model route
    -> List (Conn config model route)
connections { connDict } =
    Dict.values connDict
