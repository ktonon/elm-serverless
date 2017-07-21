const util = require('util');

const hasFunction = (obj, attr) => (
  (typeof obj === 'object') &&
  (typeof obj[attr] === 'function'));

const validate = (obj, attr, { missing, invalid }) => {
  if (!hasFunction(obj, attr)) {
    throw new Error(obj === undefined
      ? missing
      : `${invalid}: ${util.inspect(obj, { depth: 2 })}`);
  }
};

module.exports = validate;
