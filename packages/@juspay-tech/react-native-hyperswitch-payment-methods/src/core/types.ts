export type FormId = string;

export type VaultType =
  'vgs' | 'skyflow' | 'basis_theory' | 'evervault' | 'hyperswitch_vault';

export type FieldKind =
  'card_number' | 'card_expiry' | 'card_cvc' | 'card_holder';

export interface ProviderConfig {
  vault_type: VaultType;

  vault_data: any;
}

export interface FieldState {
  kind: FieldKind;
  isValid: boolean;
  isEmpty: boolean;
  isFocused: boolean;
  isDirty: boolean;
  validationErrors: string[];

  brand?: string;
}

export type SubmitStatus =
  'success' | 'error' | 'not_ready' | 'validation_error';

export interface SubmitError {
  field?: FieldKind;
  code: string;
  message: string;
}

export interface SubmitData {
  tokens?: Record<string, unknown>;

  raw?: unknown;
}

export interface SubmitResult {
  status: SubmitStatus;

  vaultType?: VaultType;
  data?: SubmitData;
  errors?: SubmitError[];
}

export type FormStatus = 'initializing' | 'ready' | 'submitting' | 'error';

export interface HyperswitchFormHandle {
  submit(providerData?: unknown): Promise<SubmitResult>;
  readonly status: FormStatus;
}

export interface WidgetHandle {
  focus(): void;
  blur(): void;
}
