module.exports = {
  dependency: {
    platforms: {
      android: {
        sourceDir: './android',
        packageImportPath: 'import com.juspaytech.reactnativehyperswitchpaypal.ReactNativeHyperswitchPaypalPackage;',
        packageInstance: 'new ReactNativeHyperswitchPaypalPackage()',
      },
    },
  },
};
