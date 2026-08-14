const path = require('path');
const { getDefaultConfig } = require('@react-native/metro-config');
const { withMetroConfig } = require('react-native-monorepo-config');

// Monorepo root: withMetroConfig reads workspaces from this package.json and
// makes all packages (e.g. @juspay-tech/react-native-hyperswitch-vault)
// resolvable by Metro.
const root = path.resolve(__dirname, '..');

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * @type {import('metro-config').MetroConfig}
 */
module.exports = withMetroConfig(getDefaultConfig(__dirname), {
  root,
  dirname: __dirname,
});
