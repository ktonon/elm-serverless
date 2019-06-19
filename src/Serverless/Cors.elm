module Serverless.Cors exposing
    ( Config, Reflectable(..)
    , configDecoder, methodsDecoder, reflectableDecoder
    , fromConfig, allowOrigin, exposeHeaders, maxAge, allowCredentials, allowMethods, allowHeaders
    , cors
    )

{-| CORS Middleware for elm-serverless.


## Types

@docs Config, Reflectable


## Decoders

@docs configDecoder, methodsDecoder, reflectableDecoder


## Middleware

@docs fromConfig, allowOrigin, exposeHeaders, maxAge, allowCredentials, allowMethods, allowHeaders


## Deprecated

@docs cors

-}

import Json.Decode exposing (Decoder, andThen, bool, fail, int, list, oneOf, string, succeed)
import Json.Decode.Pipeline exposing (optional)
import Serverless.Conn as Conn exposing (..)
import Serverless.Conn.Request exposing (Method(..), methodToString)
import Serverless.Conn.Response exposing (addHeader)



-- TYPES


{-| Specify all CORS configuration in one record.
-}
type alias Config =
    { origin : Reflectable (List String)
    , expose : List String
    , maxAge : Int
    , credentials : Bool
    , methods : List Method
    , headers : Reflectable (List String)
    }


{-| A reflectable header value.

A reflectable value can either be

  - `ReflectRequest` derive the headers from the request
  - `Exactly` set to a specific value

-}
type Reflectable a
    = ReflectRequest
    | Exactly a



-- DECODERS


{-| Decode CORS configuration from JSON.
-}
configDecoder : Decoder Config
configDecoder =
    succeed Config
        |> optional "origin" reflectableDecoder (Exactly [])
        |> optional "expose" stringListDecoder []
        |> optional "maxAge" maxAgeDecoder 0
        |> optional "credentials" truthyDecoder False
        |> optional "methods" methodsDecoder []
        |> optional "headers" reflectableDecoder (Exactly [])


{-| Decode a reflectable value from JSON.

  - `"*"` decodes to `ReflectRequest`
  - `"foo,bar"` or `["foo", "bar"]` decodes to `Exactly ["foo", "bar"]`

-}
reflectableDecoder : Decoder (Reflectable (List String))
reflectableDecoder =
    stringListDecoder
        |> andThen
            (\strings ->
                if strings == [ "*" ] then
                    succeed ReflectRequest

                else
                    strings |> Exactly |> succeed
            )


maxAgeDecoder : Decoder Int
maxAgeDecoder =
    oneOf
        [ int |> andThen positiveIntDecoder
        , string
            |> andThen
                (\w ->
                    case String.toInt w of
                        Just val ->
                            positiveIntDecoder val

                        Nothing ->
                            fail ("Decoding maxAge: not a positive integer " ++ w)
                )
        ]


positiveIntDecoder : Int -> Decoder Int
positiveIntDecoder val =
    if val < 0 then
        fail "negative value when zero or positive was expected"

    else
        succeed val


truthyDecoder : Decoder Bool
truthyDecoder =
    oneOf
        [ bool
        , int |> andThen (\val -> val /= 0 |> succeed)
        , string |> andThen (\val -> not (String.isEmpty val) |> succeed)
        ]


stringListDecoder : Decoder (List String)
stringListDecoder =
    oneOf
        [ list string
        , string |> andThen (String.split "," >> succeed)
        ]


{-| Case-insensitive decode a list of HTTP methods.
-}
methodsDecoder : Decoder (List Method)
methodsDecoder =
    stringListDecoder
        |> andThen
            (\strings ->
                case
                    strings
                        |> List.map
                            (\w ->
                                case w |> String.toLower of
                                    "get" ->
                                        Just GET

                                    "post" ->
                                        Just POST

                                    "put" ->
                                        Just PUT

                                    "delete" ->
                                        Just DELETE

                                    "options" ->
                                        Just OPTIONS

                                    _ ->
                                        Nothing
                            )
                        |> maybeList
                of
                    Just methods ->
                        succeed methods

                    Nothing ->
                        fail
                            ("Invalid CORS methods: "
                                ++ (strings |> String.join ",")
                            )
            )



-- MIDDLEWARE


{-| Set CORS headers according to a configuration record.

This function is best used when the configuration is provided externally and
decoded using `configDecoder`. For example, npm rc and AWS Lambda environment
variables can be used as the source of CORS configuration.

-}
fromConfig :
    (config -> Config)
    -> Conn config model route interop
    -> Conn config model route interop
fromConfig extract conn =
    cors (conn |> Conn.config |> extract) conn


{-| Deprecated. Use fromConfig.
-}
cors :
    Config
    -> Conn config model route interop
    -> Conn config model route interop
cors config =
    allowOrigin config.origin
        >> exposeHeaders config.expose
        >> maxAge config.maxAge
        >> allowCredentials config.credentials
        >> allowMethods config.methods
        >> allowHeaders config.headers


{-| Sets `access-control-allow-origin`.

`ReflectRequest` will reflect the request `origin` header, or if absent, will
just be set to `*`

-}
allowOrigin :
    Reflectable (List String)
    -> Conn config model route interop
    -> Conn config model route interop
allowOrigin origin conn =
    case origin of
        ReflectRequest ->
            updateResponse
                (addHeader
                    ( "access-control-allow-origin"
                    , header "origin" conn
                        |> Maybe.withDefault "*"
                    )
                )
                conn

        Exactly origins ->
            if origins |> List.isEmpty then
                conn

            else
                updateResponse
                    (addHeader
                        ( "access-control-allow-origin"
                        , origins |> String.join ","
                        )
                    )
                    conn


{-| Sets `access-control-expose-headers`.
-}
exposeHeaders :
    List String
    -> Conn config model route interop
    -> Conn config model route interop
exposeHeaders headers conn =
    if headers |> List.isEmpty then
        conn

    else
        updateResponse
            (addHeader
                ( "access-control-expose-headers"
                , headers |> String.join ","
                )
            )
            conn


{-| Sets `access-control-max-age`.

If the value is not positive, the header will not be set.

-}
maxAge :
    Int
    -> Conn config model route interop
    -> Conn config model route interop
maxAge age conn =
    if age > 0 then
        updateResponse
            (addHeader
                ( "access-control-max-age"
                , age |> String.fromInt
                )
            )
            conn

    else
        conn


{-| Sets `access-control-allow-credentials`.

Only sets the header if the value is `True`.

-}
allowCredentials :
    Bool
    -> Conn config model route interop
    -> Conn config model route interop
allowCredentials allow conn =
    if allow then
        updateResponse
            (addHeader ( "access-control-allow-credentials", "true" ))
            conn

    else
        conn


{-| Sets `access-control-allow-methods`.
-}
allowMethods :
    List Method
    -> Conn config model route interop
    -> Conn config model route interop
allowMethods methods conn =
    if methods |> List.isEmpty then
        conn

    else
        updateResponse
            (addHeader
                ( "access-control-allow-methods"
                , methods |> List.map methodToString |> String.join ","
                )
            )
            conn


{-| Sets `access-control-allow-headers`.

`ReflectRequest` will reflect the request `access-control-request-headers` headers
or if absent, it will not set the header at all.

-}
allowHeaders :
    Reflectable (List String)
    -> Conn config model route interop
    -> Conn config model route interop
allowHeaders headers conn =
    case headers of
        ReflectRequest ->
            case
                header "access-control-request-headers" conn
            of
                Just requestHeaders ->
                    updateResponse
                        (addHeader
                            ( "access-control-allow-headers"
                            , requestHeaders
                            )
                        )
                        conn

                Nothing ->
                    conn

        Exactly h ->
            if List.isEmpty h then
                conn

            else
                updateResponse
                    (addHeader
                        ( "access-control-allow-headers"
                        , h |> String.join ","
                        )
                    )
                    conn


maybeList : List (Maybe a) -> Maybe (List a)
maybeList list =
    case list |> List.take 1 of
        [ Just value ] ->
            list
                |> List.drop 1
                |> maybeList
                |> Maybe.map ((::) value)

        [] ->
            Just []

        _ ->
            Nothing
