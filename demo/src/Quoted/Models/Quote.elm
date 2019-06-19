module Quoted.Models.Quote exposing (decoder, encodeList, format, request)

import Http
import Json.Decode exposing (Decoder, string, succeed)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Json.Encode as Encode exposing (Value)
import Quoted.Types exposing (Quote)



-- MODEL


format : String -> Quote -> String
format lineBreak quote =
    quote.text ++ lineBreak ++ "--" ++ quote.author


encodeList : List Quote -> Value
encodeList quotes =
    Encode.object
        [ ( "quotes"
          , quotes
                |> List.map
                    (\quote ->
                        Encode.object
                            [ ( "lang", quote.lang |> Encode.string )
                            , ( "text", quote.text |> Encode.string )
                            , ( "author", quote.author |> Encode.string )
                            ]
                    )
                |> Encode.list identity
          )
        ]



-- DECODER


decoder : String -> Decoder Quote
decoder lang =
    succeed Quote
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
