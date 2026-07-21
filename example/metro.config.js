const path = require('path');
const { getDefaultConfig } = require('@react-native/metro-config');

const rnhsRoot = path.join(__dirname, '..', 'packages', '@juspay-tech', 'react-native-hyperswitch');

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * Set HS_MERCHANT_APP=true to simulate a pure merchant/consumer app that
 * resolves the libraries through their published entry points (dist/lib)
 * instead of the workspace source files.
 *
 * @type {import('metro-config').MetroConfig}
 */
const config = getDefaultConfig(__dirname);

const isMerchantApp = process.env.HS_MERCHANT_APP === 'true';

// Watch workspace sources for live reload in development/watch mode only.
config.watchFolders = isMerchantApp ? [] : [rnhsRoot];

config.resolver.nodeModulesPaths = [
  path.resolve(__dirname, 'node_modules'),
  path.resolve(__dirname, '..', 'node_modules'),
];

// In development/watch mode, bundle from source so edits are picked up
// without rebuilding. In merchant mode, let Metro resolve through the normal
// package.json main/module/react-native fields.
if (!isMerchantApp) {
  config.resolver.resolveRequest = (context, moduleName, platform) => {
    if (moduleName === '@juspay-tech/react-native-hyperswitch') {
      return {
        filePath: path.join(rnhsRoot, 'src', 'index.ts'),
        type: 'sourceFile',
      };
    }
    return context.resolveRequest(context, moduleName, platform);
  };
}

module.exports = config;
