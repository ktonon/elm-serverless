elm serverless
==============

[![serverless](http://public.serverless.com/badges/v3.svg)](http://www.serverless.com)
[![npm version](https://badge.fury.io/js/elm-serverless.svg)](https://badge.fury.io/js/elm-serverless)
[![Gitter chat](https://badges.gitter.im/ktonon/elm-serverless.png)](https://gitter.im/elm-serverless/Lobby)
[![CircleCI](https://circleci.com/gh/ktonon/elm-serverless.svg?style=svg)](https://circleci.com/gh/ktonon/elm-serverless)

__Experimental (WIP): Not for use in production__

Deploy an [elm][] HTTP API to [AWS Lambda][] using [serverless][].

## What is it?

* an npm package [elm-serverless][] which bridges the interface between an [AWS Lambda handler][] and your elm program
* an elm package [ktonon/elm-serverless][] which provides a framework for writing simple HTTP APIs

## Demo

Visit the [demo/](https://github.com/ktonon/elm-serverless/blob/master/demo/) folder for a simple demonstration of using `elm-serverless`.

## Project timeline

__January 21, 2017__

This is a _work in progress_. It is not at all ready for production, but my goal is to get minimum viable functionality working in about a months time (i.e. late-February). This minimum functionality includes:

* __pipelines__: chains of functions which transform the connection
* __routers__: basic routing based on HTTP method and request path. Going to try and use [evanc/url-parser][] for some of this

Even when these are done, much work will remain. For example,

* [AWS SDK for elm][]: an AWS Lambda function would be pretty limited with an interface to the rest of AWS. I don't think there is a huge amount of work to be done here as we can probably generate the elm interface from the AWS SDK json files. But it is definitely non-trivial.
* __practial middleware__: the pipelines will make this possible, but we'll still need to define middleware for things like [JWT][], body parsing, and so on...

## Collaboration

So far this is a one person project. I am open to collaboration. Post a message on [gitter][] if you are interested and we can talk about how to factor off a chunk of the work.

[AWS Lambda]:https://aws.amazon.com/lambda
[AWS Lambda handler]:http://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-handler.html
[AWS SDK for elm]:https://github.com/ktonon/aws-sdk-elm
[elm-serverless]:https://www.npmjs.com/package/elm-serverless
[elm-serverless-demo]:https://github.com/ktonon/elm-serverless-demo
[elm-webpack-loader]:https://github.com/elm-community/elm-webpack-loader
[elm]:http://elm-lang.org/
[evanc/url-parser]:http://package.elm-lang.org/packages/evancz/url-parser/latest
[gitter]:https://badges.gitter.im/ktonon/elm-serverless.png)](https://gitter.im/elm-serverless/Lobby
[JWT]:https://jwt.io/
[ktonon/elm-serverless]:http://package.elm-lang.org/packages/ktonon/elm-serverless/latest
[serverless-webpack]:https://github.com/elastic-coders/serverless-webpack
[serverless]:https://github.com/serverless/serverless
[webpack]:https://webpack.github.io/
