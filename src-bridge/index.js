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

const httpApi = ({
  handler,
  config = {},
  requestPort = 'requestPort',
  responsePort = 'responsePort',
} = {}) => {
  validate(handler, 'worker', {
    missing: `Missing handler argument.${handlerExample}Got`,
    invalid: `Invalid handler argument.${handlerExample}Got`,
  });

  const app = handler.worker(config);
  const portNames = `[${Object.keys(app.ports).join(', ')}]`;

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
