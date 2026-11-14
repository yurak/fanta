// The source code including full typescript support is available at:
// https://github.com/shakacode/react_on_rails_demo_ssr_hmr/blob/master/config/webpack/commonWebpackConfig.js

// Common configuration applying to client and server configuration
const { generateWebpackConfig, merge } = require("shakapacker");
const path = require("path");

const baseClientWebpackConfig = generateWebpackConfig({});

// clear default svg rules
const svgRule = baseClientWebpackConfig.module.rules.find((rule) => rule.test.test(".svg"));
svgRule.test = new RegExp(svgRule.test.source.replace("|svg", ""));

// use modern Sass API to suppress legacy JS API deprecation warnings
baseClientWebpackConfig.module.rules.forEach((rule) => {
  const uses = Array.isArray(rule.use) ? rule.use : (rule.oneOf || []).flatMap((r) => r.use || []);
  uses.forEach((use) => {
    if (use && use.loader && use.loader.includes("sass-loader")) {
      use.options = {
        ...use.options,
        api: "modern",
        sassOptions: {
          loadPaths: [path.resolve(__dirname, "../../node_modules")],
          quietDeps: true,
        },
      };
    }
  });
});

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
                  // Every icon is inlined into the page, and an inlined <svg> shares the document's
                  // id and style scope: svgo names each gradient "a", so seven of our bonus icons
                  // carried the same id and `url(#a)` resolved to whichever rendered first — the
                  // goal ball turned green from the clean sheet or red from the won penalty. The
                  // leftover <style> blocks collide the same way on .a/.b/.c. Prefixing both with
                  // the file name keeps every icon's colours to itself.
                  "prefixIds",
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
