const Guid = require('guid');
const requiredParams = ['handler', 'config', 'requestPort', 'responsePort'];

global.XMLHttpRequest = require("xmlhttprequest").XMLHttpRequest;

const httpApi = function(opt) {
  if (!opt || !requiredParams.every(function(param) { return opt[param] })) {
    throw new Error('httpApi requires named parameters: '
      + requiredParams.join(', '));
  }

  const app = opt.handler.worker(opt.config);

  // Allow calling library access to ports for native js interop
  if (opt.bindPorts) {
    opt.bindPorts(app);
  }

  const callbacks = {};
  app.ports[opt.responsePort].subscribe(function(resp) {
    console.log('resp: ' + JSON.stringify(resp, null, 2));
    const cb = callbacks[resp.id];
    if (cb) {
      delete callbacks[resp.id];
      cb(null, {
        statusCode: resp.statusCode,
        body: encodeBody(resp.body),
        headers: resp.headers,
      });
    } else {
      console.error('resp missing callback: ' + resp.id);
    }
  });

  return function(event, context, cb) {
    const params = event.pathParameters || {};
    const headers = event.headers || {};
    const host = headers.Host || headers.host;
    const rc = event.requestContext || { identity: {} };
    const req = {
      id: Guid.raw(),
      body: (typeof event.body === 'object'
        ? event.body && JSON.stringify(event.body)
        : event.body),
      headers: headers,
      host: headers.Host || (headers.host && headers.host.split(':')[0]),
      method: event.httpMethod || event.method,
      path: '/' + (params[0] || params['proxy'] || ''),
      port: parseInt(headers['X-Forwarded-Port'] || (host && host.split(':')[1]), 10),
      remoteIp: rc.identity.sourceIp || '127.0.0.1',
      scheme: headers['X-Forwarded-Proto'] || 'http',
      stage: (event.requestContext || {}).stage || 'local',
      queryParams: event.queryStringParameters || {},
    };

    callbacks[req.id] = cb;
    console.log('req: ' + JSON.stringify(req, null, 2));
    app.ports[opt.requestPort].send(req);
  };
};

const encodeBody = function(raw) {
  return typeof raw === 'string'
    ? raw
    : JSON.stringify(raw);
}

module.exports.httpApi = httpApi;
