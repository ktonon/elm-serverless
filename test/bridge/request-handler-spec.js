const should = require('should');
const sinon = require('sinon');
const uuid = require('uuid');

const Pool = require('../../src-bridge/pool');
const requestHandler = require('../../src-bridge/request-handler');
const spyLogger = require('./spy-logger');

const makeHandler = () => {
  const config = {
    pool: new Pool({ logger: spyLogger() }),
    requestPort: { send: sinon.spy() },
    logger: spyLogger()
  };
  return Object.assign(requestHandler(config), config);
};

const context = {};

const id = uuid.v4();

const connections = pool =>
  Object.keys(pool.connections).map(key => pool.connections[key]);

describe('requestHandler({ pool })', () => {
  it('is a function', () => {
    should(makeHandler()).be.a.Function();
  });

  it('creates a request object and puts it into the connection pool with the callback', () => {
    const h = makeHandler();
    connections(h.pool).should.be.empty();
    const callback = sinon.spy();
    h({}, context, callback);
    const [conn] = connections(h.pool);
    conn.should.be.an.Object();
    should(conn.callback).equal(callback);
    should(conn.req).be.an.Object().with.property('host');
  });

  it('does not call the callback', () => {
    const h = makeHandler();
    h({ id }, context, sinon.spy());
    const { callback } = h.pool.take(id);
    callback.called.should.be.false();
  });

  it('does send the request into elm via the request port', () => {
    const h = makeHandler();
    h.requestPort.send.called.should.be.false();
    h({ id }, context, sinon.spy());
    const { req } = h.pool.take(id);
    h.requestPort.send.calledWith([id, '__request__', req]).should.be.true();
  });

  it('leaves string bodies unchanged', () => {
    const h = makeHandler();
    const body = 'this body\'s content is a string!';
    h({ id, body }, context, sinon.spy());
    h.pool.take(id).req.body.should.equal(body);
  });

  it('JSON stringifies other types of bodies', () => {
    const h = makeHandler();
    const body = { some: { thing: [4, 'json'] } };
    h({ id, body }, context, sinon.spy());
    h.pool.take(id).req.body.should.equal('{"some":{"thing":[4,"json"]}}');
  });

  it('creates a unique id for each request', () => {
    const h = makeHandler();
    const n = 100;
    [...Array(n)].forEach(() => h({}, context, sinon.spy()));
    const ids = new Set();
    connections(h.pool).forEach(conn => ids.add(conn.id));
    ids.size.should.equal(n);
  });

  it('info logs the request', () => {
    const h = makeHandler();
    h.logger.info.called.should.be.false();
    h({}, context, sinon.spy());
    h.logger.info.called.should.be.true();
  });

  it('can get host and port from the "Host" header', () => {
    const h = makeHandler();
    h({ id, headers: { Host: 'localhost:3000' } }, context, sinon.spy());
    const { host, port } = h.pool.take(id).req;
    host.should.equal('localhost');
    port.should.equal(3000);
  });

  it('can get host and port from the "host" header', () => {
    const h = makeHandler();
    h({ id, headers: { host: 'localhost:3000' } }, context, sinon.spy());
    const { host, port } = h.pool.take(id).req;
    host.should.equal('localhost');
    port.should.equal(3000);
  });

  it('can get method from the method arg', () => {
    const h = makeHandler();
    const method = 'PUT';
    h({ id, method }, context, sinon.spy());
    h.pool.take(id).req.method.should.equal(method);
  });

  it('can get method from the httpMethod arg', () => {
    const h = makeHandler();
    const httpMethod = 'POST';
    h({ id, httpMethod }, context, sinon.spy());
    h.pool.take(id).req.method.should.equal(httpMethod);
  });

  it('normalizes the headers', () => {
    const h = makeHandler();
    const headers = {
      'Upper-Case': false,
      'lower-case': 'Things',
      'X-strange': 3,
      'Find-Me': null,
    };
    h({ id, headers }, context, sinon.spy());
    h.pool.take(id).req.headers.should.deepEqual({
      'upper-case': 'false',
      'lower-case': 'Things',
      'x-strange': '3',
    });
  });

  it('can get path from pathParameters[0]', () => {
    const h = makeHandler();
    const pathParameters = ['foo/bar/car'];
    h({ id, pathParameters }, context, sinon.spy());
    h.pool.take(id).req.path.should.equal('/foo/bar/car');
  });

  it('can get path from pathParameters.proxy', () => {
    const h = makeHandler();
    const pathParameters = { proxy: 'not/very/far' };
    h({ id, pathParameters }, context, sinon.spy());
    h.pool.take(id).req.path.should.equal('/not/very/far');
  });

  it('defaults the path to /', () => {
    const h = makeHandler();
    h({ id }, context, sinon.spy());
    h.pool.take(id).req.path.should.equal('/');
  });

  it('the "X-Forwarded-Port" header takes precedence', () => {
    const h = makeHandler();
    h({
      id,
      headers: { host: 'localhost:3000', 'X-Forwarded-Port': '3032' },
    }, context, sinon.spy());
    const { host, port } = h.pool.take(id).req;
    host.should.equal('localhost');
    port.should.equal(3032);
  });

  it('sets the remoteIp', () => {
    const h = makeHandler();
    const sourceIp = '192.168.1.1';
    h({
      id,
      requestContext: { identity: { sourceIp } },
    }, context, sinon.spy());
    h.pool.take(id).req.remoteIp.should.equal(sourceIp);
  });

  it('defaults the remoteIp to 127.0.0.1', () => {
    const h = makeHandler();
    h({ id }, context, sinon.spy());
    h.pool.take(id).req.remoteIp.should.equal('127.0.0.1');
  });

  it('sets the stage', () => {
    const h = makeHandler();
    const stage = 'production';
    h({
      id,
      requestContext: { stage },
    }, context, sinon.spy());
    h.pool.take(id).req.stage.should.equal(stage);
  });

  it('defaults the stage to local', () => {
    const h = makeHandler();
    h({ id }, context, sinon.spy());
    h.pool.take(id).req.stage.should.equal('local');
  });

  it('sets queryParams', () => {
    const h = makeHandler();
    const queryStringParameters = {
      foo: 'bar',
      car: 'far',
    };
    h({ id, queryStringParameters }, context, sinon.spy());
    h.pool.take(id).req.queryParams.should.equal(queryStringParameters);
  });

  it('defaults queryParams to {}', () => {
    const h = makeHandler();
    h({ id }, context, sinon.spy());
    h.pool.take(id).req.queryParams.should.deepEqual({});
  });

  it('sets the scheme', () => {
    const h = makeHandler();
    const scheme = 'https';
    h({
      id,
      headers: { 'X-Forwarded-Proto': scheme },
    }, context, sinon.spy());
    h.pool.take(id).req.scheme.should.equal(scheme);
  });

  it('defaults the scheme to http', () => {
    const h = makeHandler();
    h({ id }, context, sinon.spy());
    h.pool.take(id).req.scheme.should.equal('http');
  });
});
