const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const webpack = require('webpack');

const isProd = process.env.NODE_ENV === 'production';

module.exports = {
  entry: './src/api.js',
  target: 'node', // Ignores built-in modules like path, fs, etc.

  output: {
    libraryTarget: 'commonjs',
    path: path.resolve(`${__dirname}/.webpack`),
    filename: 'api.js',
  },

  module: {
    loaders: [{
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      loader: 'elm-webpack-loader',
    }],
  },

  plugins: (isProd
    ? [new UglifyJsPlugin()]
    : []
  ),
};
