const should = require('should');
const sinon = require('sinon');
const uuid = require('uuid');

const Pool = require('../../src-bridge/pool');
const spyLogger = require('./spy-logger');

const makeCallback = (retVal) => sinon.stub().returns(retVal);
const id = uuid.v4();

describe('new Pool()', () => {
  describe('put(id, req, callback) and take(id)', () => {
    it('are used to associate callbacks with identifiers', () => {
      const pool = new Pool();
      pool.put(id, {}, makeCallback('foo'));
      const { callback } = pool.take(id);
      callback.should.not.throw();
      callback().should.equal('foo');
    });
  });

  describe('put({ id }, callback)', () => {
    it('logs an error if the same id is used twice', () => {
      const pool = new Pool({ logger: spyLogger() });
      pool.put(id, {}, makeCallback());
      pool.logger.error.called.should.be.false();
      pool.put(id, {}, makeCallback());
      pool.logger.error.called.should.be.true();
    });

    it('replaces the callback if the same id is used twice', () => {
      const pool = new Pool({ logger: spyLogger() });
      pool.put(id, {}, makeCallback('foo'));
      pool.put(id, {}, makeCallback('bar'));
      pool.take(id).callback().should.equal('bar');
    });

    it('throws an error if the callback is not a function', () => {
      const pool = new Pool();
      (() => pool.put({ id }, 'call-me-baby')).should.throw();
    });
  });

  describe('take(id)', () => {
    it('logs an error if no callback is associated for the id', () => {
      const pool = new Pool({ logger: spyLogger() });
      pool.logger.error.called.should.be.false();
      pool.take(uuid.v4());
      pool.logger.error.called.should.be.true();
    });

    it('removes the callback from the pool', () => {
      const pool = new Pool({ logger: spyLogger() });
      pool.put(id, {}, makeCallback('foo'));
      pool.take(id).callback().should.equal('foo');
      pool.logger.error.called.should.be.false();
      should(pool.take(id).callback).be.undefined();
      pool.logger.error.called.should.be.true();
    });
  });
});
