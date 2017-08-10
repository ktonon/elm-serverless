port module Hello.API exposing (..)

import Serverless
import Serverless.Conn exposing (respond)
import Serverless.Conn.Body as Body exposing (text)
import Serverless.Port


{-| A Serverless.Program is parameterized by your 5 custom types

  - Config is a server load-time record of deployment specific values
  - Model is for whatever you need during the processing of a request
  - Route represents the set of routes your app will handle
  - Interop enumerates the JavaScript functions which may be called
  - Msg is your app message type

-}
main : Serverless.Program () () () () ()
main =
    Serverless.httpApi
        { configDecoder = Serverless.noConfig
        , initialModel = ()
        , parseRoute = Serverless.noRoutes
        , update = Serverless.noSideEffects
        , interop = Serverless.noInterop

        -- Entry point for new connections.
        -- This function composition passes the conn through a pipeline and then
        -- into a router (but only if the conn is not sent by the pipeline).
        , endpoint = respond ( 200, text "Hello Elm on AWS Lambda" )

        -- Provides ports to the framework which are used for requests,
        -- responses, and JavaScript interop function calls. Do not use these
        -- ports directly, the framework handles associating messages to
        -- specific connections with unique identifiers.
        , requestPort = requestPort
        , responsePort = responsePort
        }


port requestPort : Serverless.Port.Request msg


port responsePort : Serverless.Port.Response msg
