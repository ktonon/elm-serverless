# elm <img src="https://raw.githubusercontent.com/ktonon/elm-serverless/master/es-logo-small.png" width="37"> serverless

[![serverless](http://public.serverless.com/badges/v3.svg)](http://www.serverless.com)
[![elm-package](https://img.shields.io/badge/elm-3.0.2-blue.svg)](http://package.elm-lang.org/packages/ktonon/elm-serverless/latest)
[![npm version](https://img.shields.io/npm/v/elm-serverless.svg)](https://www.npmjs.com/package/elm-serverless)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/ktonon/elm-serverless/blob/master/LICENSE.txt)
[![CircleCI](https://img.shields.io/circleci/project/github/ktonon/elm-serverless/master.svg)](https://circleci.com/gh/ktonon/elm-serverless)
[![Coveralls](https://img.shields.io/coveralls/ktonon/elm-serverless.svg?label=coverage%3Ajs)](https://coveralls.io/github/ktonon/elm-serverless)
[![gitter](https://img.shields.io/gitter/room/elm-serverless/Lobby.svg)](https://gitter.im/elm-serverless/Lobby)

__Beta Release 3.0.2__

Deploy an [elm][] HTTP API to [AWS Lambda][] using [serverless][]. Define your API in elm and then use the npm package to bridge the interface between the [AWS Lambda handler][] and your elm program.


## Intro
You define a `Serverless.Program`, which among other things, is configured with a `Pipeline`.

```elm
main : Serverless.Program Config Model Msg
main =
    Serverless.httpApi
        { configDecoder = configDecoder     -- Decode once per Lambda container
        , requestPort = requestPort
        , responsePort = responsePort
        , endpoint = Endpoint               -- Processing starts with this msg
        , initialModel = Model []           -- Fresh custom model per connection
        , pipeline = pipeline               -- Pipelines process connections
        , subscriptions = subscriptions
        }

```

* pipelines are lists of `Plug`s
* each plug receives a connection (called `Conn`) and transforms it in some way
* connections contain the HTTP request, the as yet unsent response, and some other stuff which is specific to your application

Basically, the pipeline takes the place of the usual `update` function in a traditional elm app. And instead of transforming your `Model`, you transform a `Conn`, which contains your `Model`, but also has the request, response, and per deployment configuration.

```elm
pipeline : Plug
pipeline =
    Conn.pipeline
        |> plug (cors "*" [ GET, OPTIONS ]) -- Plugs transform a connection
        |> plug authentication              -- Plugs are chained in a pipeline
        -- ...
        |> fork router                      -- Routers fork pipelines

```

For routing, we use [ktonon/url-parser][], which is a fork of [evancz/url-parser][] adapted for use outside of the browser. A router function can then be used to map routes to new pipelines for handling specific tasks. Router functions can be plugged into the pipeline.

```elm
router : Conn -> Plug
router conn =
    case                                    -- Route however you want, here we
        ( conn.req.method                   -- use HTTP method
        , conn |> parseRoute route NotFound -- and parsed request path
        )
    of
        ( GET, Home ) ->
            statusCode 200
                >> textBody "Home"
                |> toResponder responsePort

            -- vvvvvvvvvv --                -- UrlParser gives structured routes
        ( GET, Quote lang ) ->
            Quote.pipeline lang             -- Defer to another module

        _ ->
            statusCode 404
                >> textBody "Nothing here"
                |> toResponder responsePort
```

## Demo

There are two demos:

* [./demo][]: which is kept in sync with the master branch of this repository
* [elm-serverless-demo][]: a separate repository which works with [![elm-package](https://img.shields.io/badge/elm--serverless-3.0.2-blue.svg)](http://package.elm-lang.org/packages/ktonon/elm-serverless/latest) (the latest release)

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
