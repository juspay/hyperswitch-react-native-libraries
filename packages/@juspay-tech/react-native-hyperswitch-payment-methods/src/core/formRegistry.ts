import type { FormId, SubmitResult } from './types';

export type FormSubmitFn = (providerData?: unknown) => Promise<SubmitResult>;

const forms = new Map<FormId, FormSubmitFn>();

export function registerForm(id: FormId, submit: FormSubmitFn): () => void {
  forms.set(id, submit);
  return () => {
    if (forms.get(id) === submit) {
      forms.delete(id);
    }
  };
}

export function getFormSubmit(id: FormId): FormSubmitFn | undefined {
  return forms.get(id);
}
