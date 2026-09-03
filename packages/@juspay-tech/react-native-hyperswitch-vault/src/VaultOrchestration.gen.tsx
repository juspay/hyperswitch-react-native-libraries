/* TypeScript file generated from VaultOrchestration.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as VaultOrchestrationJS from './VaultOrchestration.bs.js';

import type {hostBrowserInfo as VaultConfirmBody_hostBrowserInfo} from './VaultConfirmBody.gen';

import type {hostCustomerAcceptance as VaultConfirmBody_hostCustomerAcceptance} from './VaultConfirmBody.gen';

import type {hostPaymentMethodData as VaultPaymentMethodData_hostPaymentMethodData} from './VaultPaymentMethodData.gen';

import type {paymentMethodType as VaultConfirmBody_paymentMethodType} from './VaultConfirmBody.gen';

import type {paymentType as VaultConfirmBody_paymentType} from './VaultConfirmBody.gen';

import type {providerTokenizedCard as VaultConfirmBody_providerTokenizedCard} from './VaultConfirmBody.gen';

import type {vaultEndpointConfig as VaultEndpoint_vaultEndpointConfig} from './VaultEndpoint.gen';

import type {vaultEnvironment as VaultFormOptions_vaultEnvironment} from './VaultFormOptions.gen';

import type {vaultPaymentResult as VaultResult_vaultPaymentResult} from './VaultResult.gen';

export type orchestrationConfirmInput = {
  readonly tokenizedCard: VaultConfirmBody_providerTokenizedCard; 
  readonly paymentId: string; 
  readonly sdkAuthorization?: string; 
  readonly publishableKey?: string; 
  readonly clientSecret?: string; 
  readonly environment: VaultFormOptions_vaultEnvironment; 
  readonly endpoint?: VaultEndpoint_vaultEndpointConfig; 
  readonly appId?: string; 
  readonly paymentMethodType?: VaultConfirmBody_paymentMethodType; 
  readonly paymentMethodData?: VaultPaymentMethodData_hostPaymentMethodData; 
  readonly customerAcceptance?: VaultConfirmBody_hostCustomerAcceptance; 
  readonly browserInfo?: VaultConfirmBody_hostBrowserInfo; 
  readonly returnUrl?: string; 
  readonly paymentType?: VaultConfirmBody_paymentType; 
  readonly email?: string; 
  readonly timeoutMs?: number
};

export const confirmTokenizedCardPayment: (input:orchestrationConfirmInput) => Promise<VaultResult_vaultPaymentResult> = VaultOrchestrationJS.confirmTokenizedCardPayment as any;
