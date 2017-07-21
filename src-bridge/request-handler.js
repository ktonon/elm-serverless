const uuid = require('uuid');

const defaultLogger = require('./logger');

const encodeBody = body => (typeof body === 'object'
  ? body && JSON.stringify(body)
  : body);

const path = params => `/${params[0] || params.proxy || ''}`;

const splitHostPort = host => {
  const parts = typeof host === 'string' ? host.split(':') : [];
  return { host: parts[0], port: parts[1] };
};

module.exports = ({ pool, requestPort, logger = defaultLogger }) => ({
  body,
  headers = {},
  httpMethod,
  id = uuid.v4(),
  method = httpMethod,
  pathParameters,
  queryStringParameters = {},
  requestContext = {},
}, context, callback) => {
  const { host, port } = splitHostPort(headers.Host || headers.host);
  const { sourceIp } = requestContext.identity || {};
  const req = {
    body: encodeBody(body),
    headers,
    host,
    id,
    method,
    path: path(pathParameters || {}),
    port: parseInt(headers['X-Forwarded-Port'] || port, 10),
    queryParams: queryStringParameters,
    remoteIp: sourceIp || '127.0.0.1',
    scheme: headers['X-Forwarded-Proto'] || 'http',
    stage: requestContext.stage || 'local',
  };

  pool.put(req, callback);
  logger.info(JSON.stringify({ req }, null, 2));
  requestPort.send(req);
};
