import { Card, PaymentMethodTypes } from './PaymentMethodTypes';

export type CustomerDefaultSavedPaymentMethodCard = Card;

export type CustomerDefaultSavedPaymentMethod = PaymentMethodTypes & {
  card: CustomerDefaultSavedPaymentMethodCard | null;
};
