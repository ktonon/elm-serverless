const defaultLogger = require('./logger');

const missingStatusCodeBody = 'Application did not return a valid status code';

const defaultHeaders = (body) => (typeof body === 'object'
  ? { 'content-type': 'application/json; charset=utf-8' }
  : { 'content-type': 'text/text; charset=utf-8' });

const encodeBody = (body) => {
  switch (typeof body) {
    case 'string':
    case 'undefined':
      return body;
    case 'object':
      return JSON.stringify(body);
    default:
      return `${body}`;
  }
};

const handler = ({ pool, logger = defaultLogger }) => function responseHandler(resp) {
  logger.info(JSON.stringify({ resp }, null, 2));
  const { callback } = pool.take(resp.id);
  const statusCode = parseInt(resp.statusCode, 10);
  if (callback) {
    if (isNaN(statusCode)) {
      callback(null, {
        statusCode: 500,
        body: `${missingStatusCodeBody}: ${resp.statusCode}`,
        headers: defaultHeaders(''),
      });
    } else {
      callback(null, {
        statusCode,
        body: encodeBody(resp.body, statusCode),
        headers: resp.headers || defaultHeaders(resp.body),
      });
    }
  } else {
    logger.error('resp missing callback:', resp.id);
  }
};

module.exports = Object.assign(handler, {
  defaultHeaders,
  missingStatusCodeBody,
});
