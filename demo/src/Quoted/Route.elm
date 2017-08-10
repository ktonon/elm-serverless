module Quoted.Route exposing (..)

import UrlParser exposing (..)


type Route
    = Home Query
    | Quote Lang
    | Buggy
    | Number


type Lang
    = LangAll
    | Lang String


type Sort
    = Asc
    | Desc


type alias Query =
    { q : String
    , sort : Sort
    }


route : Parser (Route -> a) a
route =
    oneOf
        [ map Home (top </> query)
        , map Quote (s "quote" </> lang)
        , map Buggy (s "buggy")
        , map Number (s "number")
        ]


lang : Parser (Lang -> a) a
lang =
    oneOf
        [ map LangAll top
        , map Lang string
        ]


query : Parser (Query -> a) a
query =
    map Query
        (top
            <?> customParam "q" (Maybe.withDefault "")
            <?> customParam "sort" sort
        )


sort : Maybe String -> Sort
sort =
    Maybe.withDefault ""
        >> (\val ->
                if val == "asc" then
                    Asc
                else
                    Desc
           )
