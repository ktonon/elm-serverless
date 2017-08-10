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
const elmServerless = require('../../src-bridge');
const rc = require('strip-debug-loader!shebang-loader!rc'); // eslint-disable-line

const elm = require('./API.elm');

// Use AWS Lambda environment variables to override these values
// See the npm rc package README for more details
const config = rc('demo', {
  languages: ['en', 'ru'],

  enableAuth: 'false',

  cors: {
    origin: '*',
    methods: 'get,post,options',
  },
});

module.exports.handler = elmServerless.httpApi({
  // Your elm app is the handler
  handler: elm.API,

  // One handler per Interop type constructor
  interop: {
    // Handles `GetRandom Int`
    getRandom: upper => Math.floor(Math.random() * upper),
  },

  // Config is a record type that you define.
  // You will also provide a JSON decoder for this.
  // It should be deployment data that is constant, perhaps loaded from
  // an environment variable.
  config,

  // Because elm libraries cannot expose ports, you have to define them.
  // Whatever you call them, you have to provide the names.
  // The meanings are obvious. A connection comes in through the requestPort,
  // and the response is sent back through the responsePort.
  requestPort: 'requestPort',
  responsePort: 'responsePort',
});
