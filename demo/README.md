elm serverless demo
===================

This section demonstrates how to use [elm-serverless][]. It is included in the same repo as `elm-serverless` so that it is always up to date with the master branch. For a demo which works with [![elm-package](https://img.shields.io/badge/elm--serverless-3.0.2-blue.svg)](http://package.elm-lang.org/packages/ktonon/elm-serverless/3.0.2) (the latest release), see [elm-serverless-demo][].

__NOTE__: This project uses forked [serverless-webpack][], but there is an open [Pull Request](https://github.com/elastic-coders/serverless-webpack/pull/82). The PR adds support for [Lambda Proxy Integration][] to the local server.

## Try it

* clone this repo
* `npm install`
* `npm run demo:install`
* `npm start`
  * [http://localhost:8000/quote](http://localhost:8000/quote) will respond with quotes which it fetches from another service
* `npm run demo:deploy` to test deploying it to [AWS Lambda][]

## The break down

Two tools are involved in getting your elm app on [AWS Lambda][]:

* [webpack][] along with [elm-webpack-loader][] transpiles your elm code to JavaScript
* [serverless][] along with [serverless-webpack][] packages and deploys your app to [AWS Lambda][]

There are four files that you should check out in this demo to get a better understanding of how everything fits together. Each file is self-documenting. Take a look at:

* [serverless.yml][]: configures [serverless][] and uses the [serverless-webpack][] plugin
* [webpack.config.js][]: compiles elm using [elm-webpack-loader][]
* [api.js][]: contains the `handler` function, which is the entry point to your application, called by AWS Lambda
* [API.elm][]: contains the elm `Serverless.Program` which defines your HTTP API

[AWS Lambda]:https://aws.amazon.com/lambda
[elm-serverless]:https://github.com/ktonon/elm-serverless
[elm-serverless-demo]:https://github.com/ktonon/elm-serverless-demo
[elm-webpack-loader]:https://github.com/elm-community/elm-webpack-loader
[Lambda Proxy Integration]:http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-lambda.html#api-gateway-create-api-as-simple-proxy-for-lambda-build
[serverless]:https://serverless.com/
[serverless-webpack]:https://github.com/elastic-coders/serverless-webpack
[webpack]:https://webpack.github.io/

[API.elm]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/API.elm
[api.js]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/api.js
[serverless.yml]:https://github.com/ktonon/elm-serverless/blob/master/demo/serverless.yml
[webpack.config.js]:https://github.com/ktonon/elm-serverless/blob/master/demo/webpack.config.js
