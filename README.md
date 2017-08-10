# elm <img src="https://raw.githubusercontent.com/ktonon/elm-serverless/master/es-logo-small.png" width="37"> serverless

[![serverless](http://public.serverless.com/badges/v3.svg)](http://www.serverless.com)
[![elm-package](https://img.shields.io/badge/elm-3.0.2-blue.svg)](http://package.elm-lang.org/packages/ktonon/elm-serverless/latest)
[![npm version](https://img.shields.io/npm/v/elm-serverless.svg)](https://www.npmjs.com/package/elm-serverless)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/ktonon/elm-serverless/blob/master/LICENSE.txt)
[![CircleCI](https://img.shields.io/circleci/project/github/ktonon/elm-serverless/master.svg)](https://circleci.com/gh/ktonon/elm-serverless)
[![Coveralls](https://img.shields.io/coveralls/ktonon/elm-serverless.svg?label=coverage%3Ajs)](https://coveralls.io/github/ktonon/elm-serverless)
[![gitter](https://img.shields.io/gitter/room/elm-serverless/Lobby.svg)](https://gitter.im/elm-serverless/Lobby)

Deploy an [elm][] HTTP API to [AWS Lambda][] using [serverless][]. Define your API in elm and then use the npm package to bridge the interface between the [AWS Lambda handler][] and your elm program.

__NOTE__: The master branch is on version 4.0.0 which is not yet released. This will include the following changes from release 3.

* `Conn` and `Plug` are now opaque.
* `Plug` has been greatly simplified.
* Simpler pipelines, just `|>` chains of `Conn -> Conn` functions. However pipelines can still send responses and terminate the connection early.
* A single update function (just like an Elm SPA).
* Proper JavaScript interop. ([#2](https://github.com/ktonon/elm-serverless/issues/2))

## Example

The following is an excerpt from the [./demo][] program.

```elm
{-| A Serverless.Program is parameterized by your 5 custom types

  - Config is a server load-time record of deployment specific values
  - Model is for whatever you need during the processing of a request
  - Route represents the set of routes your app will handle
  - Interop enumerates the JavaScript functions which may be called
  - Msg is your app message type

-}
main : Serverless.Program Config Model Route Interop Msg
main =
    Serverless.httpApi
        { -- Decodes per instance configuration into Elm data. If decoding fails
          -- the server will fail to start. This decoder is called once at
          -- startup.
          configDecoder = configDecoder

        -- Each incoming connection gets this fresh model.
        , initialModel = { quotes = [] }

        -- Parses the request path and query string into Elm data.
        -- If parsing fails, a 404 is automatically sent.
        , parseRoute = UrlParser.parseString Route.route

        -- Entry point for new connections.
        -- This function composition passes the conn through a pipeline and then
        -- into a router (but only if the conn is not sent by the pipeline).
        , endpoint = Plug.apply pipeline >> Conn.mapUnsent router

        -- Update function which operates on Conn.
        , update = update

        -- Enumerates JavaScript interop functions and provides JSON coders
        -- to convert data between Elm and JSON.
        , interop = Serverless.Interop interopEncode interopDecoder

        -- Provides ports to the framework which are used for requests,
        -- responses, and JavaScript interop function calls. Do not use these
        -- ports directly, the framework handles associating messages to
        -- specific connections with unique identifiers.
        , requestPort = requestPort
        , responsePort = responsePort
        }


{-| Pipelines are chains of functions (plugs) which transform the connection.

These pipelines can optionally send a response through the connection early, for
example a 401 sent if authorization fails. Use Plug.apply to pass a connection
through a pipeline (see above). Note that Plug.apply will stop processing the
pipeline once the connection is sent.

-}
pipeline : Plug
pipeline =
    Plug.pipeline
        |> plug Middleware.cors
        |> plug Middleware.auth


{-| Just a big "case of" on the request method and route.

Remember that route is the request path and query string, already parsed into
nice Elm data, courtesy of the parseRoute function provided above.

-}
router : Conn -> ( Conn, Cmd Msg )
router conn =
    case
        ( method conn
        , route conn
        )
    of
        ( GET, Home query ) ->
            Conn.respond ( 200, text <| (++) "Home: " <| toString query ) conn

        ( _, Quote lang ) ->
            -- Delegate to Pipeline/Quote module.
            Quote.router lang conn

        ( GET, Number ) ->
            -- This one calls out to a JavaScript function named `getRandom`.
            -- The result comes in as a message `RandomNumber`.
            Conn.interop [ GetRandom 1000000000 ] conn

        ( GET, Buggy ) ->
            Conn.respond ( 500, text "bugs, bugs, bugs" ) conn

        _ ->
            Conn.respond ( 405, text "Method not allowed" ) conn


{-| The application update function.

Just like an Elm SPA, an elm-serverless app has a single update
function which handles messages resulting from interop calls and side-effects
in general.

-}
update : Msg -> Conn -> ( Conn, Cmd Msg )
update msg conn =
    case msg of
        -- This message is intended for the Pipeline/Quote module
        GotQuotes result ->
            Quote.gotQuotes result conn

        -- Result of a JavaScript interop call. The `interopDecoder` function
        -- passed into Serverless.httpApi is responsible for converting interop
        -- results into application messages.
        RandomNumber val ->
            Conn.respond ( 200, json <| Json.Encode.int val ) conn
```

On the JavaScript side, we use the npm package to create a bridge from the AWS Lambda handler to your Elm application.

```javascript
const elm = require('./API.elm');

// ...

module.exports.handler = elmServerless.httpApi({
  // Your elm app is the handler
  handler: elm.API,

  // One handler per Interop type constructor
  interop: {
    // Handles `GetRandom Int`
    getRandom: upper => Math.floor(Math.random() * upper),
  },

  // Config is a record type that you define.
  // You will also provide a JSON decoder for this.
  // It should be deployment data that is constant, perhaps loaded from
  // an environment variable.
  config: {
    enableAuth: 'false',
    languages: ['en', 'ru'],
  }

  // Because elm libraries cannot expose ports, you have to define them.
  // Whatever you call them, you have to provide the names.
  // The meanings are obvious. A connection comes in through the requestPort,
  // and the response is sent back through the responsePort.
  requestPort: 'requestPort',
  responsePort: 'responsePort',
});
```

Note there is another demo ([elm-serverless-demo][]) which targets [![elm-package](https://img.shields.io/badge/elm--serverless-3.0.2-blue.svg)](http://package.elm-lang.org/packages/ktonon/elm-serverless/latest) (the latest release).

## Middleware

The following is a list of known middleware:

* [ktonon/elm-serverless-cors][] add [CORS][] to your response headers

## Contributing

`elm-serverless` targets Node.js 6.10. To get a development environment setup, fork and clone this repo. `npm install` will also install elm packages for the base library as well as the demo. `npm test` will perform the full range of tests including:

* [./test/bridge][]: unit tests for the JavaScript package
* [./test/demo][]: end-to-end tests for the included demo
* [./test/Serverless][]: unit tests for the elm package

The demo tests are written in JavaScript using [supertest][] and [mocha][] and rely on a running test instance of the demo server, which is started automatically when you run `npm test`. You can also launch tests in watch mode with the command `npm run test:watch`.


## AWS

An AWS Lambda function would be pretty limited without an interface to the rest of AWS. [AWS SDK for elm][] is a __work in progress__. I don't think there is a huge amount of work to be done here as we can probably generate the elm interface from the AWS SDK json files. But it is definitely non-trivial.

[./demo]:https://github.com/ktonon/elm-serverless/blob/master/demo
[./test/bridge]:https://github.com/ktonon/elm-serverless/blob/master/test/bridge
[./test/demo]:https://github.com/ktonon/elm-serverless/blob/master/test/demo
[./test/Serverless]:https://github.com/ktonon/elm-serverless/blob/master/test/Serverless
[AWS Lambda handler]:http://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-handler.html
[AWS Lambda]:https://aws.amazon.com/lambda
[AWS SDK for elm]:https://github.com/ktonon/aws-sdk-elm
[CORS]:https://en.wikipedia.org/wiki/Cross-origin_resource_sharing
[elm-serverless-demo]:https://github.com/ktonon/elm-serverless-demo
[elm]:http://elm-lang.org/
[evancz/url-parser]:http://package.elm-lang.org/packages/evancz/url-parser/latest
[gitter]:https://gitter.im/elm-serverless/Lobby
[ktonon/elm-serverless-cors]:https://github.com/ktonon/elm-serverless-cors
[ktonon/url-parser]:http://package.elm-lang.org/packages/ktonon/url-parser/latest
[mocha]:https://mochajs.org/
[serverless]:https://github.com/serverless/serverless
[supertest]:https://github.com/visionmedia/supertest
