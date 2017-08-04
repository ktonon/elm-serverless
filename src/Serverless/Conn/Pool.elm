module Serverless.Conn.Pool exposing (..)

import Dict exposing (Dict)
import Logging exposing (LogLevel(..), Logger)
import Serverless.Conn as Conn exposing (Conn)
import Serverless.Conn.Request exposing (Id, Request)


-- CONNECTION POOL


type alias Pool config model =
    { connDict : Dict Id (Conn config model)
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
                    (Conn.init config pool.initialModel req)

        _ ->
            logger LogError "Failed to add request! Pool has no config" pool


get : Id -> Pool config model -> Maybe (Conn config model)
get requestId { connDict } =
    Dict.get requestId connDict


replace :
    Conn config model
    -> Pool config model
    -> Pool config model
replace conn pool =
    let
        newConnDict =
            Dict.insert (Conn.id conn) conn pool.connDict
    in
    { pool | connDict = newConnDict }


connections : Pool config model -> List (Conn config model)
connections { connDict } =
    Dict.values connDict
