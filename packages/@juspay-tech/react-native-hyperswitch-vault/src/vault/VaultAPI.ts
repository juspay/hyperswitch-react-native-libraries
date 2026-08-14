export enum VaultAPIVersion {
  v1 = 'v1',
  v2 = 'v2',
}

export const getVaultAPIPath = (version: VaultAPIVersion) => {
  switch (version) {
    case VaultAPIVersion.v1:
      return '/tokens';
    case VaultAPIVersion.v2:
      return '/aliases';
  }
};
