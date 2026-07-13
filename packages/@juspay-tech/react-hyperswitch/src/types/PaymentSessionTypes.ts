import { CustomerSavedPaymentMethodsSession } from './CustomerSavedPaymentMethodsSessionTypes';
import { PaymentSessionConfiguration } from './HyperswitchSessionTypes';
import { PaymentSheetOptions, SavedPaymentMethodsConfiguration } from './PaymentSheetTypes';
import { PaymentResult } from './PaymentTypes';

export interface PaymentSession {
  sessionHandle?: string;
  presentPaymentSheet(options?: PaymentSheetOptions): Promise<PaymentResult>;
  getCustomerSavedPaymentMethods(
    options?: SavedPaymentMethodsConfiguration,
  ): Promise<CustomerSavedPaymentMethodsSession>;
  updateIntent(intentResolver: () => Promise<PaymentSessionConfiguration>): Promise<void>;
}
