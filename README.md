# elm <img src="https://raw.githubusercontent.com/ktonon/elm-serverless/master/es-logo-small.png" width="37"> serverless

[![serverless](http://public.serverless.com/badges/v3.svg)](http://www.serverless.com)
[![elm-package](https://img.shields.io/badge/elm-4.0.1-blue.svg)](http://package.elm-lang.org/packages/ktonon/elm-serverless/latest)
[![npm version](https://img.shields.io/npm/v/elm-serverless.svg)](https://www.npmjs.com/package/elm-serverless)
[![CircleCI](https://img.shields.io/circleci/project/github/ktonon/elm-serverless/master.svg)](https://circleci.com/gh/ktonon/elm-serverless)
[![Coveralls](https://img.shields.io/coveralls/ktonon/elm-serverless.svg?label=coverage%3Ajs)](https://coveralls.io/github/ktonon/elm-serverless)

Deploy an [elm][] HTTP API to [AWS Lambda][] using [serverless][]. Define your API in elm and then use the npm package to bridge the interface between the [AWS Lambda handler][] and your elm program.


## Documentation

* [./demo][] - Best place to start learning about the framework. Contains several small programs each demonstrating a separate feature. Each demo is supported by an end-to-end suite of tests.
* [elm-serverless-demo][] - Demo programs that work with the latest release.
* [API Docs][] - Hosted on elm-lang packages, detailed per module and function documentation. Examples are doc-tested.

## Middleware

* [ktonon/elm-serverless-cors][] - Add [CORS][] to your response headers.


[API Docs]:http://package.elm-lang.org/packages/ktonon/elm-serverless/latest/Serverless
[./demo]:https://github.com/ktonon/elm-serverless/blob/master/demo
[AWS Lambda handler]:http://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-handler.html
[AWS Lambda]:https://aws.amazon.com/lambda
[CORS]:https://en.wikipedia.org/wiki/Cross-origin_resource_sharing
[elm-serverless-demo]:https://github.com/ktonon/elm-serverless-demo
[elm]:http://elm-lang.org/
[ktonon/elm-serverless-cors]:https://github.com/ktonon/elm-serverless-cors
[serverless]:https://serverless.com/
