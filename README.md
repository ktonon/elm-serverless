elm serverless
==============

[![serverless](http://public.serverless.com/badges/v3.svg)](http://www.serverless.com)
[![npm version](https://badge.fury.io/js/elm-serverless.svg)](https://badge.fury.io/js/elm-serverless)
[![Gitter chat](https://badges.gitter.im/ktonon/elm-serverless.png)](https://gitter.im/elm-serverless/Lobby)
[![CircleCI](https://circleci.com/gh/ktonon/elm-serverless.svg?style=svg)](https://circleci.com/gh/ktonon/elm-serverless)

__Experimental (WIP): Not for use in production__

Deploy an [elm][] HTTP API to [AWS Lambda][] using [serverless][].

## Demo

Clone this project, then run:

```shell
$ npm install -g elm@0.18
$ npm install
$ npm run demo:install
$ npm run demo
```

Your server will be running locally at [http://localhost:8000][]
See the [demo/README][] for more.

## What is it?

* an npm package [elm-serverless][] which bridges the interface between an [AWS Lambda handler][] and your elm program
* an elm package [ktonon/elm-serverless][] which provides a framework for writing simple HTTP APIs

## How it works

Learn by example. Take a look at [demo/src/API.elm][].

Here is a quick summary:

* you define a `Serverless.Program` which among other things, is configured with a `Pipeline`
* pipelines are lists of `Plug`s
* each plug receives a connection (called `Conn`) and transforms it in some way
* connections contain the HTTP request, the as yet unsent response, and some other stuff which is specific to your application

Basically, the pipeline takes the place of the usual `update` function in a traditional elm app. And instead of transforming your `Model`, you transform a `Conn`, which contains your `Model`, but also has the request and response stuff.

__Routing__

We use a [modified version](http://package.elm-lang.org/packages/ktonon/url-parser/latest/) of `evancz/url-parser`, adapted for use outside of the browser. A router function can then be used to map routes to new pipelines for handling specific tasks. Router functions can be plugged into the pipeline.

## Roadmap

__Updated: January 27, 2017__

This is a _work in progress_. It is missing basic functionality required for a server framework. My goal is to get minimum viable functionality working in about a months time (i.e. late-February). What remains to be implemented:

* __Routers__: basic routing is implemented now, but needs lots of testing and likely refactoring.
* __Basic middleware__: the pipelines already make this possible, but we'll still need to define middleware for things like [CORS][], [JWT][], body parsing, and so on...
* [AWS SDK for elm][]: an AWS Lambda function would be pretty limited without an interface to the rest of AWS. I don't think there is a huge amount of work to be done here as we can probably generate the elm interface from the AWS SDK json files. But it is definitely non-trivial.

## Collaboration

I am open to collaboration. Post a message on [gitter][] if you are interested and we can talk about how to factor off a chunk of the work.

[http://localhost:8000]:http://localhost:8000
[AWS Lambda]:https://aws.amazon.com/lambda
[AWS Lambda handler]:http://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-handler.html
[AWS SDK for elm]:https://github.com/ktonon/aws-sdk-elm
[CORS]:https://en.wikipedia.org/wiki/Cross-origin_resource_sharing
[demo/README]:https://github.com/ktonon/elm-serverless/blob/master/demo/README.md
[demo/src/API.elm]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/API.elm
[elm-serverless]:https://www.npmjs.com/package/elm-serverless
[elm-serverless-demo]:https://github.com/ktonon/elm-serverless-demo
[elm-webpack-loader]:https://github.com/elm-community/elm-webpack-loader
[elm]:http://elm-lang.org/
[evanc/url-parser]:http://package.elm-lang.org/packages/evancz/url-parser/latest
[gitter]:https://gitter.im/elm-serverless/Lobby
[JWT]:https://jwt.io/
[ktonon/elm-serverless]:http://package.elm-lang.org/packages/ktonon/elm-serverless/latest
[serverless-webpack]:https://github.com/elastic-coders/serverless-webpack
[serverless]:https://github.com/serverless/serverless
[webpack]:https://webpack.github.io/
