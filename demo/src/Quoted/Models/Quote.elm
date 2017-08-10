module Quoted.Models.Quote exposing (..)

import Http
import Json.Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (decode, hardcoded, required)
import Json.Encode as J
import Quoted.Types exposing (Quote)


-- MODEL


format : String -> Quote -> String
format lineBreak quote =
    quote.text ++ lineBreak ++ "--" ++ quote.author


encodeList : List Quote -> J.Value
encodeList quotes =
    J.object
        [ ( "quotes"
          , quotes
                |> List.map
                    (\quote ->
                        J.object
                            [ ( "lang", quote.lang |> J.string )
                            , ( "text", quote.text |> J.string )
                            , ( "author", quote.author |> J.string )
                            ]
                    )
                |> J.list
          )
        ]



-- DECODER


decoder : String -> Decoder Quote
decoder lang =
    decode Quote
        |> hardcoded lang
        |> required "quoteText" string
        |> required "quoteAuthor" string


request : String -> Http.Request Quote
request lang =
    decoder lang
        |> Http.get
            ("http://api.forismatic.com/api/1.0/?method=getQuote&format=json&lang="
                ++ lang
            )
