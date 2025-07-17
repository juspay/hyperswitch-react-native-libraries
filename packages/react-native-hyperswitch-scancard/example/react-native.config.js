const path = require('path');

module.exports = {
  dependencies: {
    'react-native-hyperswitch-scancard': {
      root: path.join(__dirname, '..'),
      platforms: {
        ios: {
          podspecPath: path.join(__dirname, '..', 'react-native-hyperswitch-scancard.podspec'),
        },
      },
    },
  },
};
