const should = require('should');
const sinon = require('sinon');
const uuid = require('uuid');

const Pool = require('../../src-bridge/pool');
const responseHandler = require('../../src-bridge/response-handler');
const spyLogger = require('./spy-logger');

const id = uuid.v4();

const makeHandler = () => {
  const config = { pool: new Pool({ logger: spyLogger() }), logger: spyLogger() };
  return Object.assign(responseHandler(config), config);
};

describe('responseHandler({ pool })', () => {
  it('is a function', () => {
    should(makeHandler()).be.a.Function();
  });

  it('info logs the response', () => {
    const h = makeHandler();
    h.pool.put(id, {}, () => null);
    h.logger.info.called.should.be.false();
    h(id, {});
    h.logger.error.called.should.be.false();
    h.logger.info.called.should.be.true();
  });

  it('logs an error if the callback is missing', () => {
    const h = makeHandler();
    h.logger.error.called.should.be.false();
    h(id, {});
    h.logger.error.called.should.be.true();
  });

  it('calls the callback', () => {
    const h = makeHandler();
    const cb = sinon.spy();
    h.pool.put(id, {}, cb);
    cb.called.should.be.false();
    h(id, {});
    cb.called.should.be.true();
  });

  it('calls the callback with reasonable defaults', () => {
    const h = makeHandler();
    const cb = sinon.spy();
    h.pool.put(id, {}, cb);
    h(id, {});
    cb.calledWith(null, {
      statusCode: 500,
      body: `${responseHandler.missingStatusCodeBody}: undefined`,
      headers: responseHandler.defaultHeaders(''),
      isBase64Encoded: false
    }).should.be.true();
  });

  it('calls the callback with provided response values', () => {
    const h = makeHandler();
    const cb = sinon.spy();
    h.pool.put(id, {}, cb);
    h(id, { statusCode: '404', body: 'not found' });
    cb.calledWith(null, {
      statusCode: 404,
      body: 'not found',
      headers: responseHandler.defaultHeaders(''),
      isBase64Encoded: false
    }).should.be.true();
  });

  it('JSON stringifies bodies which are objects', () => {
    const h = makeHandler();
    const cb = sinon.spy();
    h.pool.put(id, {}, cb);
    h(id, { statusCode: '200', body: { great: 'job' } });
    cb.calledWith(null, {
      statusCode: 200,
      body: '{"great":"job"}',
      headers: responseHandler.defaultHeaders({}),
      isBase64Encoded: false
    }).should.be.true();
  });

  it('uses plain text for numbers', () => {
    const h = makeHandler();
    const cb = sinon.spy();
    h.pool.put(id, {}, cb);
    h(id, { statusCode: '200', body: 42 });
    cb.calledWith(null, {
      statusCode: 200,
      body: '42',
      headers: responseHandler.defaultHeaders(''),
      isBase64Encoded: false
    }).should.be.true();
  });

  it('sets isBase64Encoded to true', () => {
    const h = makeHandler();
    const cb = sinon.spy();
    h.pool.put(id, {}, cb);
    h(id, { statusCode: '200', body: 42, isBase64Encoded: true });
    cb.calledWith(null, {
      statusCode: 200,
      body: '42',
      headers: responseHandler.defaultHeaders(''),
      isBase64Encoded: true
    }).should.be.true();
  });
});
