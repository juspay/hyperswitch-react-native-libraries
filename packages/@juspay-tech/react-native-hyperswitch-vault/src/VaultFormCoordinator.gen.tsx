/* TypeScript file generated from VaultFormCoordinator.res by genType. */

/* eslint-disable */
/* tslint:disable */

import type {hostBrowserInfo as VaultConfirmBody_hostBrowserInfo} from './VaultConfirmBody.gen';

import type {hostCustomerAcceptance as VaultConfirmBody_hostCustomerAcceptance} from './VaultConfirmBody.gen';

import type {hostPaymentMethodData as VaultPaymentMethodData_hostPaymentMethodData} from './VaultPaymentMethodData.gen';

import type {paymentCardSource as VaultCardSource_paymentCardSource} from './VaultCardSource.gen';

import type {paymentMethodType as VaultConfirmBody_paymentMethodType} from './VaultConfirmBody.gen';

import type {paymentType as VaultConfirmBody_paymentType} from './VaultConfirmBody.gen';

import type {vaultEndpointConfig as VaultEndpoint_vaultEndpointConfig} from './VaultEndpoint.gen';

export type paymentConfirmInput = {
  readonly cardSource: VaultCardSource_paymentCardSource; 
  readonly paymentId: string; 
  readonly sdkAuthorization?: string; 
  readonly publishableKey?: string; 
  readonly clientSecret?: string; 
  readonly cardholderName?: string; 
  readonly paymentMethodType?: VaultConfirmBody_paymentMethodType; 
  readonly paymentMethodData?: VaultPaymentMethodData_hostPaymentMethodData; 
  readonly customerAcceptance?: VaultConfirmBody_hostCustomerAcceptance; 
  readonly browserInfo?: VaultConfirmBody_hostBrowserInfo; 
  readonly returnUrl?: string; 
  readonly paymentType?: VaultConfirmBody_paymentType; 
  readonly email?: string; 
  readonly eligibilityRequired?: boolean; 
  readonly appId?: string; 
  readonly endpoint?: VaultEndpoint_vaultEndpointConfig; 
  readonly vaultEndpoint?: VaultEndpoint_vaultEndpointConfig
};
