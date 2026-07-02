import { createDeferred } from './deferred';
import type { ProviderAdapter } from './ProviderAdapter';
import type { FormStatus, SubmitResult, VaultType } from './types';

const DEFAULT_READY_TIMEOUT_MS = 10_000;

export interface CreateFormSessionOptions {
  readyTimeoutMs?: number;
}

export interface FormSession {
  readonly status: FormStatus;

  attachCollector(collector: unknown): void;

  fail(error: unknown): void;
  submit(providerData?: unknown): Promise<SubmitResult>;
}

function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function errorResult(
  vaultType: VaultType,
  code: string,
  message: string
): SubmitResult {
  return { status: 'error', vaultType, errors: [{ code, message }] };
}

export function createFormSession(
  adapter: ProviderAdapter,
  options: CreateFormSessionOptions = {}
): FormSession {
  const readyTimeoutMs = options.readyTimeoutMs ?? DEFAULT_READY_TIMEOUT_MS;
  const ready = createDeferred<void>();

  let collector: unknown | undefined;
  let failure: { error: unknown } | undefined;
  let status: FormStatus = 'initializing';

  async function waitForReady(): Promise<void> {
    let timer: ReturnType<typeof setTimeout> | undefined;
    const timeout = new Promise<void>((resolve) => {
      timer = setTimeout(resolve, readyTimeoutMs);
    });
    try {
      await Promise.race([ready.promise, timeout]);
    } finally {
      if (timer) clearTimeout(timer);
    }
  }

  return {
    get status() {
      return status;
    },

    attachCollector(next: unknown) {
      if (failure) return;
      collector = next;
      status = 'ready';
      ready.resolve();
    },

    fail(error: unknown) {
      failure = { error };
      status = 'error';
      ready.resolve();
    },

    async submit(providerData?: unknown): Promise<SubmitResult> {
      if (collector === undefined && !failure) {
        await waitForReady();
      }

      if (failure) {
        return errorResult(
          adapter.vaultType,
          'host_error',
          messageOf(failure.error)
        );
      }

      if (collector === undefined) {
        return {
          status: 'not_ready',
          vaultType: adapter.vaultType,
          errors: [
            {
              code: 'not_ready',
              message: `The ${adapter.vaultType} card fields are not ready yet. Try again once the form has finished initializing.`,
            },
          ],
        };
      }

      status = 'submitting';
      try {
        const result = await adapter.submit(collector, providerData);
        status = 'ready';
        return result;
      } catch (error) {
        status = 'ready';
        return errorResult(
          adapter.vaultType,
          'submit_failed',
          messageOf(error)
        );
      }
    },
  };
}
