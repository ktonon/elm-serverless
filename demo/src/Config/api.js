const elmServerless = require('../../../src-bridge');

// Webpack has trouble with shebangs (#!)
const rc = require('strip-debug-loader!shebang-loader!rc'); // eslint-disable-line

const { Elm } = require('./API.elm');

// Use AWS Lambda environment variables to override these values.
// See the npm rc package README for more details.
//
// Try changing these locally by starting the server with environment variables.
// For example,
//
//     demoConfig_someService__protocol=HttPs npm start
//
// Also try forcing the decoder to fail to see diagnostics in the logs,
//
//     demoConfig_someService__port=not-a-number npm start
//
// Of course, rc has nothing to do with elm-serverless, you can load
// configuration using another tool if you prefer.
//
const config = rc('demoConfig', {

  auth: { secret: 'secret' },

  someService: {
    protocol: 'http',
    host: 'localhost',
    // Given that these are likely to be configured with environment variables,
    // you should only use strings here, and convert them into other values
    // using Elm decoders.
    port: '3131',
  },

});

module.exports.handler = elmServerless.httpApi({
  handler: Elm.Config.API,

  // Config is a record type that you define.
  // You will also provide a JSON decoder for this.
  // It should be deployment data that is constant, perhaps loaded from
  // an environment variable.
  config,
});
