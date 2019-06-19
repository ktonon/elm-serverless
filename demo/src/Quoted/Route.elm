module Quoted.Route exposing (Lang(..), Query, Route(..), Sort(..), lang, query, queryEncoder, route, sort)

import Json.Encode as Encode
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, s, string, top)
import Url.Parser.Query as Query


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
            <?> (Query.string "q" |> Query.map (Maybe.withDefault ""))
            <?> (Query.string "sort" |> Query.map sort)
        )


queryEncoder : Query -> Encode.Value
queryEncoder qry =
    [ ( "q", Encode.string qry.q )
    , ( "sort", sortEncoder qry.sort )
    ]
        |> Encode.object


sortEncoder : Sort -> Encode.Value
sortEncoder srt =
    case srt of
        Asc ->
            Encode.string "Asc"

        Desc ->
            Encode.string "Desc"


sort : Maybe String -> Sort
sort =
    Maybe.withDefault ""
        >> (\val ->
                if val == "asc" then
                    Asc

                else
                    Desc
           )
