# Contributing

## Running Tests

`elm-serverless` targets Node.js 6.10. To get a development environment setup, fork and clone this repo. `npm install` will also install elm packages for the base library as well as the demo. `npm test` will perform the full range of tests including:

* [./test/bridge][]: unit tests for the JavaScript package
* [./test/demo][]: end-to-end tests for the included demo
* [./test/Serverless][]: unit tests for the elm package

The demo tests are written in JavaScript using [supertest][] and [mocha][] and rely on a running test instance of the demo server, which is started automatically when you run `npm test`. You can also launch tests in watch mode with the command `npm run test:watch`.

## Formatting

This project uses [elm-format](https://github.com/avh4/elm-format/releases/tag/0.7.0-exp) release 0.7.0-exp.

```shell
npm install -g elm-format@exp
```

[Editor plugins](https://github.com/avh4/elm-format#editor-integration) are available to apply formatting on each save.

[./test/bridge]:https://github.com/ktonon/elm-serverless/blob/master/test/bridge
[./test/demo]:https://github.com/ktonon/elm-serverless/blob/master/test/demo
[./test/Serverless]:https://github.com/ktonon/elm-serverless/blob/master/test/Serverless
[mocha]:https://mochajs.org/
[supertest]:https://github.com/visionmedia/supertest
