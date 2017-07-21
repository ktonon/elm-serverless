elm serverless demo
===================

This folder provides an example usage of [elm-serverless][].

## Run locally

We use [serverless-offline][] to run the server locally during development. To get started, clone this repo and then:

* `cd demo`
* `npm install`
* `npm start`

Which will start a server listening on port `3000`. [http://localhost:3000/quote](http://localhost:3000/quote) will respond with quotes which it fetches from another service

## Deploy to AWS Lambda

Setup `AWS_REGION`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY` in your environment. Make sure you have sufficient permissions to perform a serverless deployment (either admin rights, or [something more restricted](https://github.com/serverless/serverless/issues/1439)). Then `npm run deploy` from within the `demo` folder. If all goes well you'll see something like this in the output:

```shell
endpoints:
  ANY - https://***.execute-api.us-east-1.amazonaws.com/dev/
  ANY - https://***.execute-api.us-east-1.amazonaws.com/dev/{proxy+}
```

Call the first endpoint to test your deployed function.

## End-to-end testing

Black box tests are written in JavaScript using [supertest][] and [mocha][]. Before running tests, start a test server on port `3001` with the command `npm run test-server`. A nice way to run tests during development is to run the test server in the background, and the tests in watch mode. For example,

```shell
> npm run test-server &
> npm test -- --watch
```

The server can later be stopped with `kill %1`.

## How it works

Two tools are involved in getting your elm app on [AWS Lambda][]:

* [webpack][] along with [elm-webpack-loader][] compiles your elm code to JavaScript
* [serverless][] along with [serverless-webpack][] packages and deploys your app to [AWS Lambda][]

There are four files that you should check out in this demo to get a better understanding of how everything fits together:

1. [serverless.yml][]: configures [serverless][] and uses two plugins
    * [serverless-webpack][] for building the AWS Lambda function using Webpack
    * [serverless-offline][] for running the AWS Lambda function locally
    * running `npm start` invokes both of these in parallel
2. [webpack.config.js][]: compiles elm using [elm-webpack-loader][]
3. [api.js][]: contains the `handler` function, which is the entry point to your application, called by AWS Lambda
4. [API.elm][]: contains the elm `Serverless.Program` which defines your HTTP API

[API.elm]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/API.elm
[api.js]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/api.js
[AWS Lambda]:https://aws.amazon.com/lambda
[elm-serverless]:https://github.com/ktonon/elm-serverless
[elm-webpack-loader]:https://github.com/elm-community/elm-webpack-loader
[mocha]:https://mochajs.org/
[serverless-offline]:https://github.com/dherault/serverless-offline
[serverless-webpack]:https://github.com/elastic-coders/serverless-webpack
[serverless.yml]:https://github.com/ktonon/elm-serverless/blob/master/demo/serverless.yml
[serverless]:https://serverless.com/
[supertest]:https://github.com/visionmedia/supertest
[webpack.config.js]:https://github.com/ktonon/elm-serverless/blob/master/demo/webpack.config.js
[webpack]:https://webpack.github.io/
