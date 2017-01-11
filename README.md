elm serverless
==============

Deploy an [elm][] HTTP API to [AWS Lambda][] using [serverless][].

## How To

See the [elm-serverless-demo][] to get started. It uses [webpack][] with [elm-webpack-loader][] to compile to JavaScript, and then [serverless-webpack][] to deploy the whole thing to [AWS Lambda][].

## What this project adds

__Still a work in progress__

This project provides a small JavaScript package to bootstrap an HTTP API written in elm. It also provides an elm package to get the HTTP `Request` into your model and means to end the elm update loop with an HTTP `Response`.

[AWS Lambda]:https://aws.amazon.com/lambda
[elm-serverless-demo]:https://github.com/ktonon/elm-serverless-demo
[elm-webpack-loader]:https://github.com/elm-community/elm-webpack-loader
[elm]:http://elm-lang.org/
[serverless-webpack]:https://github.com/elastic-coders/serverless-webpack
[serverless]:https://github.com/serverless/serverless
[webpack]:https://webpack.github.io/
