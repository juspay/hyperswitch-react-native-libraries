export interface VgsVaultData {
  vault_id: string;
  environment?: string;
  route_id?: string;
  cname?: string;
}

export interface VgsSubmitOptions {
  path?: string;
  method?: string;
  extraData?: Record<string, unknown>;
}
