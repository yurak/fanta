// The source code including full typescript support is available at:
// https://github.com/shakacode/react_on_rails_demo_ssr_hmr/blob/master/config/webpack/commonWebpackConfig.js

// Common configuration applying to client and server configuration
const { generateWebpackConfig, merge } = require("shakapacker");
const path = require("path");

console.log("__dirname", __dirname);

const baseClientWebpackConfig = generateWebpackConfig({});

// clear default svg rules
const svgRule = baseClientWebpackConfig.module.rules.find((rule) => rule.test.test(".svg"));
svgRule.test = new RegExp(svgRule.test.source.replace("|svg", ""));

const commonOptions = {
  resolve: {
    extensions: [".css", ".ts", ".tsx"],
    alias: {
      "@": path.resolve(__dirname, "../../app/client"),
    },
  },
  module: {
    rules: [
      {
        test: /\.(ts|tsx)$/,
        loader: "ts-loader",
      },
      {
        test: /\.svg$/,
        use: [
          {
            loader: "@svgr/webpack",
            options: {
              svgoConfig: {
                plugins: [
                  {
                    name: "preset-default",
                    params: {
                      overrides: {
                        removeViewBox: false,
                      },
                    },
                  },
                ],
              },
            },
          },
        ],
      },
    ],
  },
};

// Copy the object using merge b/c the baseClientWebpackConfig and commonOptions are mutable globals
const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions);

module.exports = commonWebpackConfig;
