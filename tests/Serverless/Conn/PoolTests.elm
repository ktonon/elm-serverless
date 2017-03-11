module Serverless.Conn.PoolTests exposing (all)

import Expect
import Expect.Extra as Expect exposing (regexPattern)
import Json.Encode
import Serverless.Conn as Conn
import Serverless.Conn.Pool as Pool
import Serverless.Conn.Response as Response exposing (Response, Status, setStatus)
import Serverless.Conn.Test as Test
import Test exposing (describe, test)


all : Test.Test
all =
    describe "Serverless.Pool"
        [ describe "empty"
            [ test "creates a pool with no connections" <|
                \_ ->
                    Expect.equal 0 (Pool.size Pool.empty)
            ]
        , describe "replace"
            [ Test.conn "adds a connection to a pool" <|
                \conn ->
                    Expect.equal
                        1
                        (Pool.empty
                            |> Pool.replace conn
                            |> Pool.size
                        )
            , Test.conn "replaces an existing connection in a pool" <|
                \conn ->
                    Expect.match
                        (regexPattern "\"statusCode\":403\\b")
                        (Pool.empty
                            |> Pool.replace conn
                            |> Pool.replace (Conn.updateResponse (setStatus 403) conn)
                            |> Pool.get (Conn.id conn)
                            |> Maybe.map (Conn.jsonEncodedResponse >> Json.Encode.encode 0)
                            |> Maybe.withDefault ""
                        )
            ]
        , describe "remove"
            [ Test.conn "removes a connection from a pool" <|
                \conn ->
                    Expect.equal
                        0
                        (Pool.empty
                            |> Pool.replace conn
                            |> Pool.remove conn
                            |> Pool.size
                        )
            , Test.conn "does nothing if the connection is not in the pool" <|
                \conn ->
                    Expect.equal
                        0
                        (Pool.empty
                            |> Pool.remove conn
                            |> Pool.size
                        )
            ]
        ]


initResponseTest : String -> (Response -> Expect.Expectation) -> Test.Test
initResponseTest label e =
    test label <|
        \_ ->
            e Response.init
