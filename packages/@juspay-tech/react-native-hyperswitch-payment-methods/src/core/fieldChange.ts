import type { ElementType, FieldChange } from './types';

/** The web SDK's brand spellings, for the strings each provider reports. */
const BRANDS: Record<string, string> = {
  visa: 'Visa',
  mastercard: 'Mastercard',
  master: 'Mastercard',
  mc: 'Mastercard',
  amex: 'AmericanExpress',
  americanexpress: 'AmericanExpress',
  discover: 'Discover',
  diners: 'DinersClub',
  dinersclub: 'DinersClub',
  jcb: 'JCB',
  unionpay: 'UnionPay',
  maestro: 'Maestro',
  rupay: 'RuPay',
  cartesbancaires: 'CartesBancaires',
  interac: 'Interac',
};

export function canonicalBrand(raw: unknown): string | undefined {
  if (typeof raw !== 'string') return undefined;
  const trimmed = raw.trim();
  if (!trimmed) return undefined;
  return BRANDS[trimmed.toLowerCase().replace(/[\s_-]/g, '')] ?? trimmed;
}

export interface FieldChangeInput {
  empty: boolean;
  valid: boolean;
  touched?: boolean;
  brand?: unknown;
  error?: string;
}

/** Builds the web-shaped change from what a provider reports. */
export function fieldChange(
  elementType: ElementType,
  input: FieldChangeInput
): FieldChange {
  const change: FieldChange = {
    elementType,
    empty: input.empty,
    complete: !input.empty && input.valid,
    valid: input.valid,
    touched: input.touched ?? !input.empty,
  };
  const brand = canonicalBrand(input.brand);
  if (brand !== undefined) change.brand = brand;
  if (input.error) change.error = input.error;
  return change;
}
