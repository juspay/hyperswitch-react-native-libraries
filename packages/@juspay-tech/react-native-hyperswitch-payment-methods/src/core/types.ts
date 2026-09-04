export type FormId = string;

/**
 * The external vaults this package drives. Hyperswitch's own vault is
 * `@juspay-tech/react-native-hyperswitch-vault`, which shares this vocabulary.
 */
export type VaultType = 'vgs' | 'skyflow' | 'basis_theory' | 'evervault';

/** The web SDK's field identifiers, plus the cardholder name. */
export type ElementType =
  'cardNumber' | 'cardExpiry' | 'cardCvc' | 'cardholderName';

/** The web SDK's `vaultDetails` option: which vault, and what it needs, in camelCase. */
export interface VaultDetails {
  vaultType: VaultType;

  vaultData: unknown;
}

/** `onReady`, `onFocus`, `onBlur` on a field. */
export interface FieldEvent {
  elementType: ElementType;
}

/**
 * `onChange` on a field: the web's `{elementType, empty, complete, valid, brand?, error?}` plus
 * `touched`. No member ever carries a card value.
 */
export interface FieldChange {
  elementType: ElementType;
  empty: boolean;
  complete: boolean;
  valid: boolean;
  brand?: string;
  error?: string;
  touched: boolean;
}

/**
 * The web's `cardDetailsChange` payload. A provider's secure input keeps the digits to itself, so
 * a member it cannot report is `null`; the flags are derived from the fields' own changes.
 */
export interface CardDetails {
  bin: string | null;
  last4: string | null;
  brand: string | null;
  expiryMonth: string | null;
  expiryYear: string | null;
  formattedExpiry: string | null;
  isCardNumberComplete: boolean;
  isCvcComplete: boolean;
  isExpiryComplete: boolean;
  isCardNumberValid: boolean;
  isExpiryValid: boolean;
}

/** `onReady` on the form. */
export interface CardFormEvent {
  elementType: 'cardForm';
}

/** `onChange` on the form: the web's `cardDetailsChange` envelope plus a per-field summary. */
export interface CardFormChange {
  elementType: 'cardForm';
  eventName: 'cardDetailsChange';
  payload: CardDetails;

  /** Every mounted field is complete. */
  complete: boolean;
  /** Every mounted field is valid. */
  valid: boolean;
  /** The latest change per mounted field. */
  fields: Partial<Record<ElementType, FieldChange>>;
}

export type TokenizeStatus = 'success' | 'validation_error' | 'error';

export type TokenizeErrorType = 'validation_error' | 'api_error' | 'card_error';

export type TokenizeErrorCode =
  /** A field is empty or malformed. */
  | 'validation_error'
  /** No form is mounted for the id given to `HyperswitchPaymentMethods.tokenize`. */
  | 'incomplete_field_set'
  /** The provider's SDK has not finished initialising. */
  | 'sdk_not_ready'
  /** The provider refused, answered unreadably, or failed to initialise. */
  | 'tokenization_failed';

/** The web's error envelope: `code`, `message`, `type`. */
export interface TokenizeError {
  code: TokenizeErrorCode;
  message: string;
  type: TokenizeErrorType;
}

export interface TokenizeData {
  /** Provider tokens, keyed the way the provider keys them. */
  tokens?: Record<string, unknown>;

  /** The provider's own payload. */
  raw?: unknown;
}

export type TokenizeResult =
  | { status: 'success'; vaultType?: VaultType; data?: TokenizeData }
  | {
      status: 'validation_error' | 'error';
      vaultType?: VaultType;
      error: TokenizeError;
    };

export type FormStatus = 'initializing' | 'ready' | 'tokenizing' | 'error';

export interface CardFormHandle {
  tokenize(providerData?: unknown): Promise<TokenizeResult>;
  readonly status: FormStatus;
}

export interface FieldHandle {
  focus(): void;
  blur(): void;
  clear(): void;
}
