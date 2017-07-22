const xmlhttprequest = require('xmlhttprequest');

const Pool = require('./pool');
const requestHandler = require('./request-handler');
const responseHandler = require('./response-handler');
const validate = require('./validate');

global.XMLHttpRequest = xmlhttprequest.XMLHttpRequest;

const handlerExample = `
If the Serverless.Program is defined in API.elm then the handler is:

    const handler = require('./API.elm').API;
`;

const invalidElmApp = msg => {
  throw new Error(`handler.worker did not return valid Elm app.${msg}`);
};

const httpApi = ({
  handler,
  config = {},
  requestPort = 'requestPort',
  responsePort = 'responsePort',
} = {}) => {
  validate(handler, 'worker', {
    missing: `Missing handler argument.${handlerExample}`,
    invalid: `Invalid handler argument.${handlerExample}Got`,
  });

  const app = handler.worker(config);
  if (typeof app !== 'object') {
    invalidElmApp(`Got: ${validate.inspect(app)}`);
  }
  const portNames = `[${Object.keys(app.ports).sort().join(', ')}]`;

  validate(app.ports[responsePort], 'subscribe', {
    missing: `No response port named ${responsePort} among: ${portNames}`,
    invalid: 'Invalid response port',
  });

  validate(app.ports[requestPort], 'send', {
    missing: `No request port named ${requestPort} among: ${portNames}`,
    invalid: 'Invalid request port',
  });

  const pool = new Pool();
  app.ports[responsePort].subscribe(responseHandler({ pool }));
  return requestHandler({ pool, requestPort: app.ports[requestPort] });
};

module.exports = { httpApi };
