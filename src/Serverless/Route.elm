module Serverless.Route exposing (..)

{-| Thin layer for use with UrlParser.

@docs parseRoute
-}

import Dict exposing (empty)
import UrlParser exposing (Parser, (</>), oneOf, parse, map, int, s)
import Serverless.Types exposing (Conn)


{-| Converts a UrlParser.Parser into middleware.

    import UrlParser exposing (Parser, (</>), s, int, top, map, oneOf)
    import Serverless.Route exposing (parseRoute)


    type Route
        = Home
        | Cheers Int


    route : Parser (Route -> a) a
    route =
        oneOf
            [ map Home top
            , map Cheers (s "cheers" </> int)
            ]


    myPipeline =
        pipeline
            |> plug (parseRoute route)

After the middleware is applied, your `Conn` will have a `route` set to
`Just route` if the parsing succeeded, or `Nothing` if parsing failed.
-}
parseRoute : Parser (route -> route) route -> route -> Conn config model -> route
parseRoute router defaultRoute conn =
    UrlParser.parse router conn.req.path empty
        |> Maybe.withDefault defaultRoute
