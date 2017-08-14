# Demo <img src="https://raw.githubusercontent.com/ktonon/elm-serverless/master/es-logo-small.png" width="37"> Programs

This folder provides an example usage of [elm-serverless][].

## Run locally

We use [serverless-offline][] to run the server locally during development. To get started, clone this repo and then:

* `npm install`
* `npm start`

Which will start a server listening on port `3000`. Note that the demo includes multiple, independent, elm-serverless programs which are deployed as a bundle. Each program contains:

* `API.elm` - the main entry point of the Elm HTTP API
* `api.js` - a small bridge from JavaScript to Elm

Learn by reading the demos in the following order:

| Demo            | Path              | Description                          |
| --------------- | ----------------- | ------------------------------------ |
| [Hello][]       | [/][]             | Bare bones hello world app.          |
| [Routing][]     | [/routing][]      | Parse request path into Elm data.    |
| [Forms][]       | [/forms][]        | Shows how to parse a JSON body.      |
| [Config][]      | [/config][]       | Load per-instance configuration.     |
| [Pipelines][]   | [/pipelines][]    | Build chains of middleware.          |
| [SideEffects][] | [/side-effects][] | Handle effects in the update loop.   |
| [Interop][]     | [/interop][]      | Call JavaScript functions.           |
| [Quoted][]      | [/quoted][]       | Shows one way to organize a project. |

See [serverless.yml][] and [webpack.config.js][] for details on how elm-serverless apps get mapped to base paths.

## Deploy to AWS Lambda

Setup `AWS_REGION`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY` in your environment. Make sure you have sufficient permissions to perform a serverless deployment (either admin rights, or [something more restricted](https://github.com/serverless/serverless/issues/1439)). Then `npm run deploy:demo`. If all goes well you'll see something like this in the output:

```shell
endpoints:
  ANY - https://***.execute-api.us-east-1.amazonaws.com/dev/
  ANY - https://***.execute-api.us-east-1.amazonaws.com/dev/{proxy+}
```

Call the first endpoint to test your deployed function.

## How it works

Two tools are involved in getting your elm app on [AWS Lambda][]:

* [webpack][] along with [elm-webpack-loader][] compiles your elm code to JavaScript
* [serverless][] along with [serverless-webpack][] packages and deploys your app to [AWS Lambda][]

[/]:http://localhost:3000
[/config]:http://localhost:3000/config
[/forms]:http://localhost:3000/forms
[/interop]:http://localhost:3000/interop
[/pipelines]:http://localhost:3000/pipelines
[/quoted]:http://localhost:3000/quoted
[/quoted/number]:http://localhost:3000/quoted/number
[/quoted/quote]:http://localhost:3000/quoted/quote
[/routing]:http://localhost:3000/routing
[/side-effects]:http://localhost:3000/side-effects

[Config]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/Config
[Forms]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/Forms
[Hello]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/Hello
[Interop]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/Interop
[Pipelines]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/Pipelines
[Quoted]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/Quoted
[Routing]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/Routing
[SideEffects]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/SideEffects

[API.elm]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/API.elm
[api.js]:https://github.com/ktonon/elm-serverless/blob/master/demo/src/api.js
[AWS Lambda]:https://aws.amazon.com/lambda
[elm-serverless]:https://github.com/ktonon/elm-serverless
[elm-webpack-loader]:https://github.com/elm-community/elm-webpack-loader
[serverless-offline]:https://github.com/dherault/serverless-offline
[serverless-webpack]:https://github.com/elastic-coders/serverless-webpack
[serverless.yml]:https://github.com/ktonon/elm-serverless/blob/master/demo/serverless.yml
[serverless]:https://serverless.com/
[webpack.config.js]:https://github.com/ktonon/elm-serverless/blob/master/demo/webpack.config.js
[webpack]:https://webpack.github.io/
