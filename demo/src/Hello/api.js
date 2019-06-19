// You would normally:
//
//    npm install -S elm-serverless
//
// and then require it like this:
//
//    const elmServerless = require('elm-serverless');
//
// but this demo is nested in the `elm-serverless` repo, so we just
// require it relative to the current module's location
//
const elmServerless = require('../../../src-bridge');

// Import the elm app
const { Elm } = require('./API.elm');

// Create an AWS Lambda handler which bridges to the Elm app.
module.exports.handler = elmServerless.httpApi({

  // Your elm app is the handler
  handler: Elm.Hello.API,

  // Because elm libraries cannot expose ports, you have to define them.
  // Whatever you call them, you have to provide the names.
  // The meanings are obvious. A connection comes in through the requestPort,
  // and the response is sent back through the responsePort.
  //
  // These are the default values, so if you follow the convention of naming
  // your ports in this way, you can omit these options.
  requestPort: 'requestPort',
  responsePort: 'responsePort',
});
