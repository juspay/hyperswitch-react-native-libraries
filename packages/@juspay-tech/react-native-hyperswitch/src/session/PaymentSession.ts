import type {
  HyperswitchConfiguration,
  PaymentSession,
  PaymentSessionConfiguration,
} from '../types/definitions';
import {
  updateIntentInitForAllWidgets,
  updateIntentCompleteForAllWidgets,
} from '../widget/WidgetRegistry';
import {
  bindGetCustomerSavedPaymentMethods,
  bindPresentPaymentSheet,
} from './binders';

export async function updateIntent(
  intentResolver: () => Promise<PaymentSessionConfiguration>
): Promise<void> {
  try {
    const initResults = await updateIntentInitForAllWidgets();
    initResults.forEach((result) => {
      if (result.status === 'failed') {
        console.error('Error updating intent for widget:', result.message);
      }
    });
  } catch (e) {
    console.error('Error preparing widgets for intent update:', e);
    return;
  }

  let newIntent: PaymentSessionConfiguration;
  try {
    newIntent = await intentResolver();
  } catch (e) {
    console.error('Error resolving new intent:', e);
    return;
  }

  try {
    const completeResults = await updateIntentCompleteForAllWidgets(
      newIntent.sdkAuthorization
    );
    completeResults.forEach((result) => {
      if (result.status === 'failed') {
        console.error(
          'Error completing intent update for widget:',
          result.message
        );
      }
    });
  } catch (e) {
    console.error('Error finalizing widget intent update:', e);
  }
}

export function createPaymentSession(
  hyperswitchConfig: HyperswitchConfiguration,
  paymentSessionConfig: PaymentSessionConfiguration
): PaymentSession {
  const bindings = { hyperswitchConfig, paymentSessionConfig };
  return {
    presentPaymentSheet: bindPresentPaymentSheet(bindings),
    getCustomerSavedPaymentMethods:
      bindGetCustomerSavedPaymentMethods(bindings),
    updateIntent,
  };
}
