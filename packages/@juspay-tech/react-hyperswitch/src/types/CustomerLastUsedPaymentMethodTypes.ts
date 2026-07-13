import { Card, PaymentMethodTypes } from './PaymentMethodTypes';

export type CustomerLastUsedPaymentMethodCard = Card;

export type CustomerLastUsedPaymentMethod = PaymentMethodTypes & {
  card: CustomerLastUsedPaymentMethodCard | null;
};
