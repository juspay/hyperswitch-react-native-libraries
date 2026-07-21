import { Platform } from 'react-native';
import {
  CvcWidgetOptions,
  PaymentElementOptions,
} from '@juspay-tech/react-native-hyperswitch';
import { LayoutType, SubscriptionEvent } from '@juspay-tech/react-native-hyperswitch';

export const initialBaseUrl =
  Platform.OS === 'android' ? 'http://10.0.2.2:5252' : 'http://localhost:5252';

export const publishableKey = process.env.HYPERSWITCH_PUBLISHABLE_KEY ?? '';
export const profileId = process.env.PROFILE_ID ?? '';

export const getCustomisationOptions = (
  layout: LayoutType = 'tabs'
): PaymentElementOptions => ({
  subscribedEvents: [
    'PAYMENT_METHOD_INFO_CARD',
    'PAYMENT_METHOD_STATUS',
    'FORM_STATUS',
  ] as SubscriptionEvent[],
  displayDefaultSavedPaymentIcon: false,
  paymentMethodLayout: {
    type: layout,
    radios: false,
    maxAccordionItems: 2,
    defaultCollapsed: true,
    spacedAccordionItems: true,
    cvcIcon: 'hidden',
    cardBrandIcon: 'hideGeneric',
    showCheckedIconForSelection: true,
    savedMethodCustomization: {
      cvcIcon: 'hidden',
      hideCardExpiry: true,
      defaultCollapsed: false,
      groupingBehavior: { displayInSeparateScreen: false },
      hiddenPaymentMethods: ['paypal', 'google_pay', 'apple_pay'],
    },
  },
  appearance: {
    theme: 'Light',
    shapes: {
      borderRadius: 16.0,
      borderWidth: 1.0,
      inputHeight: 56.0,
      gap: 24.0,
      shadow: {
        color: '#000000',
        opacity: 0,
        blurRadius: 0,
        intensity: 0,
        offset: { x: 0, y: 0 },
      },
    },
    primaryButton: {
      height: 56.0,
    },
    logo: {
      borderRadius: 50,
      colors: {
        light: {
          backgroundColor: 'black',
          unselected: 'white',
        },
        dark: {
          backgroundColor: 'white',
          unselected: 'black',
        },
      },
    },
  },
  splitCardFields: true,
});

export const getCvcInputOptions = (): CvcWidgetOptions => ({
  subscribedEvents: ['CVC_STATUS'],
  appearance: {
    colors: {
      light: {
        primary: '#0066CC',
        componentBackground: '#FFFFFF',
        componentBorder: '#CCCCCC',
        componentText: '#333333',
        placeholderText: '#999999',
        error: '#CC0000',
      },
      dark: {
        primary: '#4DA6FF',
        componentBackground: '#1A1A1A',
        componentBorder: '#444444',
        componentText: '#FFFFFF',
        placeholderText: '#888888',
        error: '#FF4444',
      },
    },
    shapes: {
      borderRadius: 0,
      borderWidth: 0,
      shadow: {
        color: '#000000',
        opacity: 0,
        blurRadius: 0,
        intensity: 0,
        offset: { x: 0, y: 0 },
      },
    },
  },
  placeholder: '123',
  cvcIcon: 'hidden',
  
});

export const getStatus = (paymentStatus: string | undefined): string => {
  const status = paymentStatus ?? 'Unknown';
  return status.length > 1
    ? status.charAt(0).toUpperCase() + status.slice(1)
    : status;
};

export const getErrorMessage = (error: unknown): string => {
  if (typeof error === 'string') {
    return error;
  }
  if (error instanceof Error) {
    return error.message;
  }
  return JSON.stringify(error);
};
