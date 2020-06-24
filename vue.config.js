const webpack = require('webpack')
module.exports = {
  "transpileDependencies": [
    "vuetify"
  ],
  configureWebpack: {
    plugins: [
      new webpack.DefinePlugin({
        'process.env': {
          PACKAGE_JSON: '"' + escape(JSON.stringify(require('./package.json'))) + '"'
        }
      })
    ]
  }
}
