import type { FieldKind } from '../../core/types';

export interface SkyflowVaultData {
  vault_id: string;
  vault_url: string;
  table: string;
  bearer_token?: string;
  columns?: Partial<Record<FieldKind, string>>;
  options?: Record<string, unknown>;
}

export interface SkyflowSubmitOptions {
  tokens?: boolean;
}
