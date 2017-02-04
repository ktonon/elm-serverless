const path = require('path');
const webpack = require('webpack');

const isProd = process.env.NODE_ENV === 'production';

module.exports = {
  entry: './src/api.js',
  noParse: /\.elm$/,
  target: 'node',

  output: {
    libraryTarget: 'commonjs',
    path: path.resolve(`${__dirname}/public`),
    filename: 'api.js',
  },

  module: {
    loaders: [
      // Sets up the elm loader
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack',
      },
    ],
  },

  plugins: (isProd
    ? [new webpack.optimize.UglifyJsPlugin({ compress: { warnings: false } })]
    : []
  ),
};
