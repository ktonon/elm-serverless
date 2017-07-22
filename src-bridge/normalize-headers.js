const norm = oldHeaders => {
  const headers = {};
  Object.keys(oldHeaders).forEach(key => {
    const val = oldHeaders[key];
    if (val !== undefined && val !== null) {
      headers[key.toLowerCase()] = `${val}`;
    }
  });
  return headers;
};

module.exports = norm;
