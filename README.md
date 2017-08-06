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

## Intro

You define a `Serverless.Program`.

```elm
main : Serverless.Program Config Model Route Msg
main =
    Serverless.httpApi
        { configDecoder = configDecoder -- Decode once per Lambda container
        , requestPort = requestPort
        , responsePort = responsePort
        , endpoint = Endpoint           -- Processing starts with this msg
        , initialModel = Model []       -- Fresh custom model per connection
        , parseRoute = parseRoute       -- String -> Route
        , update = update               -- Msg -> Conn -> (Conn, Cmd Msg)
        , subscriptions = subscriptions
        }

```

The main difference between an Elm SPA and a Serverless app is that the update function operates on a `Conn config model route` instead of just the app `model`. As you can see from the type name, a `Conn` is parameterized with three types specific to your application.

* `config` is a server load-time record of deployment specific values. It is initialized once per AWS Lambda instance. It is immutable and all connections share the same value.
* `model` is for whatever you need during the processing of a request. It is initialized to `initialModel` (in the above example `Model []`) for each incoming request.
* `route` represents the set of routes your app will handle. By the time your app gets to handle the request, that path and query will already be parsed into nice Elm data (using the `parseRoute` function which you provide). If parsing fails, a 404 is automatically sent.

In addition to these the conn also contains the HTTP request and pending HTTP response, and a globally unique identifier.

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
