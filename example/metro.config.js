const path = require('path');

const packagePath = path.join(__dirname, '../');

/**
 * Metro configuration for React Native
 * https://github.com/facebook/react-native
 *
 * @format
 */
module.exports = {
  resolver: {
    // don't omit the first path!! I am curious about nodeModulesPaths documentation!!
    nodeModulesPaths: [path.join(__dirname, './node_modules'), packagePath],
  },
  watchFolders: [packagePath],

  transformer: {
    getTransformOptions: async () => ({
      transform: {
        experimentalImportSupport: false,
        inlineRequires: true,
      },
    }),
  },
};
