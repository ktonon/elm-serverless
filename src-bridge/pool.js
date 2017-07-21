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

  put(req, callback) {
    if (this.connections[req.id] !== undefined) {
      this.logger.error(`Duplicate connection ID: ${req.id}`);
    }
    if (typeof callback !== 'function') {
      throw new Error(`Callback is not a function: ${callback}`);
    }
    this.connections[req.id] = { req, callback };
  }
}

module.exports = Pool;
