import { Platform } from 'react-native';
import {
  type PresentPaymentSheetParams,
  type PaymentEventName,
  type CvcAppearance,
} from '@juspay-tech/react-native-hyperswitch';

export const initialBaseUrl =
  Platform.OS === 'android' ? 'http://10.0.2.2:5252' : 'http://localhost:5252';

export const getCustomisationOptions = (layout='tabs') => {
  const options: PresentPaymentSheetParams = {
    appearance: {
      theme: 'Light',
      layout: layout,
      colors: {
        dark: {
          background: '#F9FAFB',
          componentBackground: '#00000030',
          componentText: 'white',
          primary: '#2563EB',
          primaryText: 'white',
        },
      },
      primaryButton: {
        primaryButtonColor: {
          dark: {
            background: '#1D4ED8',
          },
        },
        shapes: {
          borderRadius: 36,
        },
      },
      shapes: {
        shadow: {
          color: '#1D4ED8',
          opacity: 1,
          blurRadius: 10,
          offset: {
            x: 0,
            y: 6,
          },
        },
      },
      font: {
        // family: 'serif',
        // scale: 1.5,
        // placeholderTextSizeAdjust: 5.0,
      },
    },
    primaryButtonLabel: 'Complete Purchase',
    subscribedEvents: [
      'PAYMENT_METHOD_INFO_CARD',
      'PAYMENT_METHOD_STATUS',
      'FORM_STATUS',
      'CVC_STATUS',
      
    ] as PaymentEventName[],
    hideConfirmButton : true
  };

  return options;
};

export const getCvcInputOptions = (): { appearance: CvcAppearance } => {
  return {
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
        borderRadius: 8.0,
        borderWidth: 1.0,
      },
      font: {
        family: 'serif',
        // scale: 1.5,
        // placeholderTextSizeAdjust: 5.0,
      },
    },
  };
};

export const getStatus = (paymentStatus: any) => {
  let status = paymentStatus ?? 'Unknown';
  return status.length > 1
    ? status.charAt(0).toUpperCase() + status.slice(1)
    : status;
};

export const getErrorMessage = (error: any) => {
  if (typeof error === 'string') {
    return error;
  } else if (error instanceof Error) {
    return error.message;
  } else {
    return JSON.stringify(error);
  }
};
