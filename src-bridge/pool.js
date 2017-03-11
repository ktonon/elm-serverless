const defaultLogger = require('./logger');

class Pool {
  constructor({ logger = defaultLogger } = {}) {
    this.connections = {};
    this.logger = logger;
  }

  take(id) {
    const conn = this.connections[id];
    if (conn === undefined) {
      this.logger.error(`No callback for ID: ${id}`);
    } else {
      delete this.connections[id];
    }
    return conn || {};
  }

  put(id, req, callback) {
    if (this.connections[id] !== undefined) {
      this.logger.error(`Duplicate connection ID: ${id}`);
    }
    if (typeof callback !== 'function') {
      throw new Error(`Callback is not a function: ${callback}`);
    }
    this.connections[id] = { req, callback, id };
  }
}

module.exports = Pool;
