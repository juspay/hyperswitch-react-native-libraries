/** Error codes for Hyperswitch Vault SDK errors. */
export enum HyperswitchVaultErrorCode {
  // *** Text input data errors ***
  // When input data is not valid, but required to be valid
  InputDataIsNotValid = 1001,
  // *** Files data errors ***
  // When can't find file on device
  InputFileNotFound = 1101,
  // When file format not supported
  InputFileTypeIsNotSupported = 1102,
  // When file size is larger then allowed limit
  InputFileSizeExceedsTheLimit = 1103,
  // When can't get access to file source
  SourceNotAvailable = 1150,
  // *** Other errors ***
  // When token is null or empty.
  IvalidAccessToken = 1300,
  // When Vault config URL is not valid.
  InvalidVaultConfiguration = 1470,
  // When Vault config URL is not valid.
  InvalidConfigurationURL = 1480,
}
