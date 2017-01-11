port module Serverless.Response exposing (..)

-- MODEL


type alias StatusCode =
    Int


type alias ResponseBody =
    String



-- SUBSCRIPTIONS


port response : ( StatusCode, ResponseBody ) -> Cmd msg
