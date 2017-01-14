elm serverless
==============

__Experimental (WIP): Not for use in production__

Deploy an [elm][] HTTP API to [AWS Lambda][] using [serverless][].

## Demo

See the [elm-serverless-demo][] for an example.

## What this project adds

This project provides a small JavaScript package ([elm-serverless][]) to bootstrap an HTTP API written in elm. It also provides an elm package ([ktonon/elm-serverless][]) which provides the framework for writing a server.

## Getting started

Two tools are involved in getting your elm app on [AWS Lambda][]:

* [webpack][] along with [elm-webpack-loader][] transpiles your elm code to JavaScript
* [serverless][] along with [serverless-webpack][] packages and deploys your app to [AWS Lambda][]

Here is a sample setup. Again, you can check out [elm-serverless-demo][] for a complete working example.

```yaml
# serverless.yml

service: your-project-name

provider:
  name: aws
  runtime: nodejs4.3

# The webpack plugin will transpile elm to JavaScript
plugins:
  - serverless-webpack
custom:
  webpack: ./webpack.config.js

functions:
  api:
    handler: api.handler # Refers to function `handler` exported from `api.js`
    events:
      # The following sets up Lambda Proxy Integration
      # Basically, the elm app will do the routing instead of
      # API Gateway
      - http:
          integration: lambda-proxy
          path: /
          method: ANY
      - http:
          integration: lambda-proxy
          path: /{proxy+}
          method: ANY
```

```js
// webpack.config.js

const path = require('path');

module.exports = {
  entry: './api.js',
  noParse: /\.elm$/,
  target: 'node',

  output: {
    libraryTarget: 'commonjs',
    path: path.resolve(`${__dirname}/public`),
    filename: 'api.js',
  },

  module: {
    loaders: [
      // VVV This is the important part VVV
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack',
      },
    ],
  },
};
```

```js
// api.js

const elmServerless = require('elm-serverless');
const elm = require('./API.elm');

module.exports.handler = elmServerless.httpApi({
  // Your elm app is the handler
  handler: elm.API,

  // Config is a record type that you define.
  // You will also provide a JSON decoder for this.
  // It should be deployment data that is constant, perhaps loaded from
  // an environment variable.
  config: {
    something: 'testing config loader',
  },

  // Because elm libraries cannot expose ports, you have to define them.
  // Whatever you call them, you have to provide the names.
  // The meanings are obvious. A connection comes in through the requestPort,
  // and the response is sent back through the responsePort.
  requestPort: 'requestPort',
  responsePort: 'responsePort',
});
```

```elm
-- API.elm

port module API exposing (..)

import Json.Decode
import Serverless
import Serverless.Conn exposing (..)
import Serverless.Conn.Response exposing (..)


{-| A Serverless.Program is parameterized by your 3 custom types

* Config is a server load-time record of deployment specific values
* Model is for whatever you need during the processing of a request
* Msg is your app message type
-}
main : Serverless.Program Config Model Msg
main =
    Serverless.httpApi
        { configDecoder = configDecoder
        , requestPort = requestPort
        , responsePort = responsePort
        , endpoint = Endpoint
        , initialModel = Model 0
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


{-| Serverless.Conn.Conn is short for connection.

It is parameterized by the Config and Model record types.
For convenience we create an alias.
-}
type alias Conn =
    Serverless.Conn.Conn Config Model


{-| Can be anything you want, you just need to provide a decoder
-}
type alias Config =
    { something : String
    }


{-| Can be anything you want.
This will get set to initialModel (see above) for each incomming connection.
-}
type alias Model =
    { counter : Int
    }


configDecoder : Json.Decode.Decoder Config
configDecoder =
    Json.Decode.map Config (Json.Decode.at [ "something" ] Json.Decode.string)



-- UPDATE


{-| Your custom message type.

The only restriction is that it has to contain an endpoint. You can call the
endpoint whatever you want, but it accepts no parameters, and must be provided
to the program as `endpoint` (see above).
-}
type Msg
    = Endpoint


update : Msg -> Conn -> ( Conn, Cmd Msg )
update msg conn =
    case msg of
        -- The endpoint signals the start of a new connection.
        -- You don't have to send a response right away, but we do here to
        -- keep the example simple.
        Endpoint ->
            Debug.log "conn: "
                conn
                |> statusCode Ok_200
                |> body (TextBody ("Got a request: " ++ conn.req.path))
                |> send responsePort



-- SUBSCRIPTIONS


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg


subscriptions : Conn -> Sub Msg
subscriptions _ =
    Sub.none
```

[AWS Lambda]:https://aws.amazon.com/lambda
[elm-serverless]:https://www.npmjs.com/package/elm-serverless
[elm-serverless-demo]:https://github.com/ktonon/elm-serverless-demo
[elm-webpack-loader]:https://github.com/elm-community/elm-webpack-loader
[elm]:http://elm-lang.org/
[ktonon/elm-serverless]:http://package.elm-lang.org/packages/ktonon/elm-serverless/latest
[serverless-webpack]:https://github.com/elastic-coders/serverless-webpack
[serverless]:https://github.com/serverless/serverless
[webpack]:https://webpack.github.io/
