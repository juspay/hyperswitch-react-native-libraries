import { getFormSubmit } from './core/formRegistry';
import type { FormId, SubmitResult } from './core/types';

export const HyperswitchPaymentMethods = {
  async submit(id: FormId, providerData?: unknown): Promise<SubmitResult> {
    const submit = getFormSubmit(id);
    if (!submit) {
      return {
        status: 'error',
        errors: [
          {
            code: 'no_form',
            message: `No <HyperswitchForm id="${id}"> is currently mounted. Pass that id to a form, or call submit() on the form ref instead.`,
          },
        ],
      };
    }
    return submit(providerData);
  },
};
