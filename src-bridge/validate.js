const util = require('util');

const hasFunction = (obj, attr) => (
  (typeof obj === 'object') &&
  (typeof obj[attr] === 'function'));

const inspect = (val) => util.inspect(val, { depth: 2 });

const validate = (obj, attr, { missing, invalid }) => {
  if (!hasFunction(obj, attr)) {
    throw new Error(obj === undefined
      ? missing
      : `${invalid}: ${inspect(obj)}`);
  }
};

module.exports = validate;
module.exports.inspect = inspect;
