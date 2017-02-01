module Route exposing (..)

import UrlParser exposing (..)


type Route
    = Home
    | Quote Lang
    | Buggy
    | NotFound


type Lang
    = LangAll
    | Lang String


route : Parser (Route -> a) a
route =
    oneOf
        [ map Home top
        , map Quote (s "quote" </> lang)
        , map Buggy (s "buggy")
        ]


lang : Parser (Lang -> a) a
lang =
    oneOf
        [ map LangAll top
        , map Lang (string)
        ]
