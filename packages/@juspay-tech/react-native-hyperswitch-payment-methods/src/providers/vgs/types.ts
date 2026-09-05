/** `vaultDetails.vaultData` for VGS, in the web's camelCase. */
export interface VgsVaultData {
  vaultId: string;
  environment?: string;
  routeId?: string;
  cname?: string;
}

/** `tokenize(providerData)` for VGS. */
export interface VgsTokenizeOptions {
  path?: string;
  method?: string;
  extraData?: Record<string, unknown>;
}
