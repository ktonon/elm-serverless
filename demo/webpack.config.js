const path = require('path');
const webpack = require('webpack');

const config = {
  entry: {
    config: './src/Config/api.js',
    forms: './src/Forms/api.js',
    hello: './src/Hello/api.js',
    interop: './src/Interop/api.js',
    pipelines: './src/Pipelines/api.js',
    quoted: './src/Quoted/api.js',
    routing: './src/Routing/api.js',
    sideEffects: './src/SideEffects/api.js',
  },
  target: 'node', // Ignores built-in modules like path, fs, etc.

  output: {
    libraryTarget: 'commonjs',
    path: path.resolve(`${__dirname}/.webpack`),
    filename: '[name].js',
  },

  module: {
    loaders: [{
      // Compiles elm to JavaScript.
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      loader: 'elm-webpack-loader',
    }],
  },
};

if (process.env.NODE_ENV === 'production') {
  // Bridge is written for node 6.10. While AWS Lambda supports it
  // the UglifyJsPlugin does not :( so until that happens we use babel.
  config.module.loaders.push({
    test: /\.js$/,
    exclude: [/elm-stuff/, /node_modules/],
    loader: 'babel-loader',
    options: { presets: 'env' },
  });

  config.plugins = config.plugins || [];
  config.plugins.push(new webpack.optimize.UglifyJsPlugin());
}

module.exports = config;
