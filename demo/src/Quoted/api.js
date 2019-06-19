const elmServerless = require('../../../src-bridge');
const rc = require('strip-debug-loader!shebang-loader!rc'); // eslint-disable-line

const { Elm } = require('./API.elm');

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
  handler: Elm.Quoted.API,
  requestPort: 'requestPort',
  responsePort: 'responsePort',

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
});
