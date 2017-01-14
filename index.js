const Guid = require('guid');
const requiredParams = ['handler', 'config', 'requestPort', 'responsePort'];

const httpApi = (opt) => {
  if (!opt || !requiredParams.every(param => opt[param])) {
    throw new Error(`httpApi requires named parameters: ${requiredParams.join(', ')}`);
  }

  const app = opt.handler.worker(opt.config);

  const callbacks = {};
  app.ports[opt.responsePort].subscribe(resp => {
    console.log(`resp: ${JSON.stringify(resp, null, 2)}`);
    const cb = callbacks[resp.id];
    if (cb) {
      delete callbacks[resp.id];
      cb(null, {
        statusCode: resp.statusCode,
        body: resp.body,
      });
    } else {
      console.error(`resp missing callback: ${resp.id}`);
    }
  });

  return (event, context, cb) => {
    const params = event.pathParameters || {};
    const req = {
      id: Guid.raw(),
      method: event.httpMethod || event.method,
      path: `/${params[0] || params['proxy'] || ''}`,
      stage: (event.requestContext || {}).stage || 'local',
    };
    callbacks[req.id] = cb;
    console.log(`req:  ${JSON.stringify(req, null, 2)}`);
    app.ports[opt.requestPort].send(req);
  };
};

module.exports.httpApi = httpApi;
