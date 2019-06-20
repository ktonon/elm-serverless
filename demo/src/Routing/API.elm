port module Routing.API exposing (Conn, Route(..), main, requestPort, responsePort, router)

import Serverless
import Serverless.Conn exposing (method, respond, route, textBody)
import Serverless.Conn.Request exposing (Method(..))
import Url
import Url.Parser exposing ((</>), map, oneOf, s, string, top)


{-| This is the route parser demo.

We use a routing function as the endpoint, and provide a route parsing function.

-}
main : Serverless.Program () () Route ()
main =
    Serverless.httpApi
        { configDecoder = Serverless.noConfig
        , initialModel = ()
        , update = Serverless.noSideEffects
        , requestPort = requestPort
        , responsePort = responsePort

        -- Parses the request path and query string into Elm data.
        -- If parsing fails, a 404 is automatically sent.
        , parseRoute =
            oneOf
                [ map Home top
                , map BlogList (s "blog")
                , map Blog (s "blog" </> string)
                ]
                |> Url.Parser.parse

        -- Entry point for new connections.
        , endpoint = router
        }


{-| Routes are represented using an Elm type.
-}
type Route
    = Home
    | BlogList
    | Blog String


{-| Perhaps the String -> Url bit should be part of the elm-serverless framework?
-}
routeParser url =
    Url.fromString url
        |> Maybe.andThen
            (Url.Parser.parse
                (oneOf
                    [ map Home top
                    , map BlogList (s "blog")
                    , map Blog (s "blog" </> string)
                    ]
                )
            )


{-| Just a big "case of" on the request method and route.

Remember that route is the request path and query string, already parsed into
nice Elm data, courtesy of the parseRoute function provided above.

-}
router : Conn -> ( Conn, Cmd msg )
router conn =
    case ( method conn, route conn ) of
        ( GET, Home ) ->
            respond ( 200, textBody "The home page" ) conn

        ( GET, BlogList ) ->
            respond ( 200, textBody "List of recent posts..." ) conn

        ( GET, Blog slug ) ->
            respond ( 200, textBody <| (++) "Specific post: " slug ) conn

        _ ->
            respond ( 405, textBody "Method not allowed" ) conn


{-| For convenience we defined our own Conn with arguments to the type parameters
-}
type alias Conn =
    Serverless.Conn.Conn () () Route


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg
