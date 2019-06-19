module Logging exposing (LogLevel(..), Logger, defaultLogger, logLevelToInt, logger, nullLogger)

{-| Available Log levels
-}


type LogLevel
    = LogDebug
    | LogInfo
    | LogWarn
    | LogError


{-| Used to order log levels
-}
logLevelToInt : LogLevel -> Int
logLevelToInt level =
    case level of
        LogDebug ->
            0

        LogInfo ->
            1

        LogWarn ->
            2

        LogError ->
            3


{-| A logger function
-}
type alias Logger a =
    LogLevel -> String -> a -> a


{-| A logger that only logs messages at a minimum log level

    logger Info -- will not log Debug level messages

-}
logger : LogLevel -> Logger a
logger minLevel level label val =
    if (minLevel |> logLevelToInt) > (level |> logLevelToInt) then
        Debug.log (Debug.toString level ++ ": " ++ label) val

    else
        val


{-| Log level that is used throughout the internal library code
-}
defaultLogger : Logger a
defaultLogger =
    logger LogInfo


{-| Disable logging completely.
-}
nullLogger : Logger a
nullLogger level label val =
    val
