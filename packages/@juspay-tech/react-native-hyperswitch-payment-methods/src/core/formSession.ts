import { createDeferred } from './deferred';
import type { ProviderAdapter } from './ProviderAdapter';
import { errorResult, messageOf } from './results';
import type { FormStatus, TokenizeResult } from './types';

const DEFAULT_READY_TIMEOUT_MS = 10_000;

export interface CreateFormSessionOptions {
  readyTimeoutMs?: number;
}

export interface FormSession {
  readonly status: FormStatus;

  attachCollector(collector: unknown): void;

  fail(error: unknown): void;
  tokenize(providerData?: unknown): Promise<TokenizeResult>;
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
  let inFlight: Promise<TokenizeResult> | undefined;

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

  async function run(providerData?: unknown): Promise<TokenizeResult> {
    if (collector === undefined && !failure) {
      await waitForReady();
    }

    if (failure) {
      return errorResult(
        adapter.vaultType,
        'tokenization_failed',
        messageOf(failure.error)
      );
    }

    if (collector === undefined) {
      return errorResult(
        adapter.vaultType,
        'sdk_not_ready',
        `The ${adapter.vaultType} card fields are not ready yet. Try again once the form has finished initializing.`
      );
    }

    status = 'tokenizing';
    try {
      const result = await adapter.tokenize(collector, providerData);
      status = 'ready';
      return result;
    } catch (error) {
      status = 'ready';
      return errorResult(
        adapter.vaultType,
        'tokenization_failed',
        messageOf(error)
      );
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

    /* Two calls at once share one request, as the Hyperswitch vault form does. */
    tokenize(providerData?: unknown): Promise<TokenizeResult> {
      if (inFlight) return inFlight;
      const pending = run(providerData).finally(() => {
        if (inFlight === pending) inFlight = undefined;
      });
      inFlight = pending;
      return pending;
    },
  };
}
