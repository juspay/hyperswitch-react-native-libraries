import type { FormId, TokenizeResult } from './types';

export type FormTokenizeFn = (
  providerData?: unknown
) => Promise<TokenizeResult>;

const forms = new Map<FormId, FormTokenizeFn>();

export function registerForm(id: FormId, tokenize: FormTokenizeFn): () => void {
  forms.set(id, tokenize);
  return () => {
    if (forms.get(id) === tokenize) {
      forms.delete(id);
    }
  };
}

export function getFormTokenize(id: FormId): FormTokenizeFn | undefined {
  return forms.get(id);
}
