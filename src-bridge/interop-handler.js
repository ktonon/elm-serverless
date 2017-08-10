module.exports = ({ interop, resultPort }) =>
  (id, key, jsonValue) => {
    const func = interop[key];
    if (!func) {
      throw new Error(`Missing interop handler '${key}' among: ${Object.keys(interop)}`);
    }
    const val = func(jsonValue);
    if (val.then && typeof val.then === 'function') {
      return val.then((val_) => {
        resultPort.send([id, key, val_]);
      });
    }
    resultPort.send([id, key, val]);
    return null;
  };
