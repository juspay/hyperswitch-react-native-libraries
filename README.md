# Hyperswitch React Native Integration Guide

The `@juspay-tech/react-native-hyperswitch` package provides a seamless way to integrate Hyperswitch payments into your React Native applications. This guide covers requirements, server-side setup, installation, configuration, and implementation.

## Requirements

Before integrating the SDK, ensure your environment meets the following requirements:

### Runtime Requirements

| Requirement | Minimum Version |
|---|---|
| Node.js | 18.x or later |
| React Native | 0.71.0 or later |
| React | 18.0.0 or later |
| iOS | 13.0 or later |
| Android | API level 21 (Android 5.0) or later |
| Xcode | 14.0 or later |
| Android Studio | Electric Eel or later |

### Peer Dependencies

The SDK requires the following peer dependencies to be installed in your project:

```bash
npm install react-native-svg react-native-inappbrowser-reborn react-native-webview
# or
yarn add react-native-svg react-native-inappbrowser-reborn react-native-webview
```

| Package | Purpose |
|---|---|
| `react-native-svg` | Renders payment method icons |
| `react-native-inappbrowser-reborn` | Handles web redirect payment flows (e.g. bank redirects) |
| `react-native-webview` | Renders embedded web content within the SDK |

### Hyperswitch Account

You will need:
- A [Hyperswitch account](https://app.hyperswitch.io) (sandbox or production)
- A **Publishable Key** (`pk_snd_...` for sandbox, `pk_prd_...` for production) — used in the client app
- A **Secret Key** (`snd_xxxxxxxx_xxxxxxxxxxxxxxxxxxxxxxxx` for sandbox, `prd_xxxxxxxx_xxxxxxxxxxxxxxxxxxxxxxxx` for production) — used **only** on your server, never in the client app

---

## Installation

```bash
npm install @juspay-tech/react-native-hyperswitch
# or
yarn add @juspay-tech/react-native-hyperswitch
```

### iOS Setup

Run CocoaPods to link the native dependencies:

```bash
cd ios && pod install
```

### Android Setup

No additional steps are required for Android. Ensure `minSdkVersion` is set to at least `21` in your `android/build.gradle`.

### React Native New Architecture (CodeGen)

If your project uses React Native's New Architecture, generate the required native bindings:

```bash
npx react-native codegen
```

> **Note:** This step can be skipped for projects using the Old Architecture. If you encounter build issues, clean the Android build first: `cd android && ./gradlew clean`.

---

## Server-side: Creating a Payment Intent

The `clientSecret` required to initialize a payment session must be created **on your server** by calling the Hyperswitch Payments API. Never expose your Secret Key in client-side code.

### API Endpoint

```
POST https://sandbox.hyperswitch.io/payments
```

Use `https://api.hyperswitch.io/payments` for production.

### Request Headers

| Header | Value |
|---|---|
| `Content-Type` | `application/json` |
| `api-key` | Your Hyperswitch Secret Key |

### Request Body

```json
{
  "amount": 1000,
  "currency": "USD",
  "profile_id": "pro_your_profile_id"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `amount` | integer | Required | Amount in the smallest currency unit (e.g. cents for USD) |
| `currency` | string | Required | ISO 4217 currency code (e.g. `"USD"`, `"EUR"`) |
| `profile_id` | string | Optional | Your Hyperswitch Business Profile ID |
| `customer_id` | string | Optional | Associate the payment with a customer |
| `description` | string | Optional | Description of the payment |
| `metadata` | object | Optional | Key-value pairs for additional data |

### Example Server (Node.js / Express)

```js
const express = require('express');
const app = express();
app.use(express.json());

const HYPERSWITCH_SECRET_KEY = process.env.HYPERSWITCH_SECRET_KEY;
const HYPERSWITCH_BASE_URL = 'https://sandbox.hyperswitch.io';

app.post('/create-payment-intent', async (req, res) => {
  try {
    const response = await fetch(`${HYPERSWITCH_BASE_URL}/payments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': HYPERSWITCH_SECRET_KEY,
      },
      body: JSON.stringify({
        amount: 1000,
        currency: 'USD',
        profile_id: process.env.PROFILE_ID,
        ...req.body,
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      return res.status(response.status).json({ error: data });
    }

    // Return only the clientSecret to the client — never the full response.
    // The Hyperswitch API returns `client_secret` (snake_case); we rename it
    // to `clientSecret` (camelCase) for the React Native client to consume.
    res.json({ clientSecret: data.client_secret });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create payment intent' });
  }
});

app.listen(3000);
```

### Example Server (Python / Flask)

```python
import os
import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

HYPERSWITCH_SECRET_KEY = os.environ['HYPERSWITCH_SECRET_KEY']
HYPERSWITCH_BASE_URL = 'https://sandbox.hyperswitch.io'

@app.route('/create-payment-intent', methods=['POST'])
def create_payment_intent():
    payload = {
        'amount': 1000,
        'currency': 'USD',
        'profile_id': os.environ.get('PROFILE_ID'),
        **request.json,
    }
    response = requests.post(
        f'{HYPERSWITCH_BASE_URL}/payments',
        headers={
            'Content-Type': 'application/json',
            'api-key': HYPERSWITCH_SECRET_KEY,
        },
        json=payload,
    )
    data = response.json()
    if not response.ok:
        return jsonify({'error': data}), response.status_code
    return jsonify({'clientSecret': data['client_secret']})

if __name__ == '__main__':
    app.run(port=3000)
```

### Response

Your server should return the `client_secret` from the Hyperswitch API response to the client app:

```json
{
  "clientSecret": "pay_xxxxxxxxxxxxxxxxxxxxxxxx_secret_yyyyyy"
}
```

---

## Basic Setup

### 1. Install and Configure

After installing the package and its peer dependencies, wrap your root component with `HyperProvider`, passing your **Publishable Key**:

```tsx
import { HyperProvider } from '@juspay-tech/react-native-hyperswitch';

export default function App() {
  return (
    <HyperProvider publishableKey="pk_snd_your_publishable_key_here">
      <PaymentScreen />
    </HyperProvider>
  );
}
```

`HyperProvider` must be an ancestor of any component that calls `useHyper()`. It is typically placed at the root of your application.

### 2. Initialize a Payment Session

Inside a component wrapped by `HyperProvider`, use the `useHyper()` hook to initialize a payment session with the `clientSecret` retrieved from your server:

```tsx
import { useCallback, useEffect, useState } from 'react';
import {
  useHyper,
  type InitPaymentSessionParams,
  type InitPaymentSessionResult,
} from '@juspay-tech/react-native-hyperswitch';

export default function PaymentScreen() {
  const { initPaymentSession, presentPaymentSheet } = useHyper();
  const [ready, setReady] = useState(false);

  const setup = useCallback(async (): Promise<void> => {
    try {
      // Fetch the clientSecret from your backend
      const response = await fetch('https://your-server.com/create-payment-intent', {
        method: 'POST',
      });

      if (!response.ok) {
        throw new Error(`Server error: ${response.status}`);
      }

      const { clientSecret } = await response.json();

      const params: InitPaymentSessionParams = {
        paymentIntentClientSecret: clientSecret,
      };

      const result: InitPaymentSessionResult = await initPaymentSession(params);

      if (result.error) {
        console.error('Payment session initialization failed:', result.error);
      } else {
        setReady(true);
      }
    } catch (error) {
      console.error('Setup failed:', error);
    }
  }, [initPaymentSession]);

  useEffect(() => {
    setup();
  }, [setup]);

  // ... render checkout button when ready
}
```

---

## Present Sheet

Once the payment session has been initialized, call `presentPaymentSheet()` to display the payment UI. This launches a native payment sheet where the user can enter their payment details and complete the transaction.

```tsx
import {
  useHyper,
  type PresentPaymentSheetParams,
  type PresentPaymentSheetResult,
} from '@juspay-tech/react-native-hyperswitch';

export default function PaymentScreen() {
  const { presentPaymentSheet } = useHyper();

  const checkout = async (): Promise<void> => {
    const options: PresentPaymentSheetParams = {
      primaryButtonLabel: 'Complete Purchase',
      appearance: {
        theme: 'Light',
      },
    };

    const result: PresentPaymentSheetResult = await presentPaymentSheet(options);
    const { error, paymentResult } = result;

    if (error) {
      // Payment failed or was cancelled
      console.error('Payment error code:', error.code);
      console.error('Payment error message:', error.message);
    } else {
      // Payment completed
      console.log('Payment status:', paymentResult?.status);   // e.g. "succeeded"
      console.log('Payment message:', paymentResult?.message);
    }
  };

  return (
    <TouchableOpacity onPress={checkout}>
      <Text>Pay Now</Text>
    </TouchableOpacity>
  );
}
```

### `PresentPaymentSheetResult`

| Field | Type | Description |
|---|---|---|
| `error` | `{ code?: string; message?: string }` | Present when the payment failed or was cancelled |
| `paymentResult` | `{ status: string; message: string; error?: string; type?: string }` | Present when the payment sheet closed after a result |

#### `paymentResult.status` values

| Value | Description |
|---|---|
| `"succeeded"` | Payment completed successfully |
| `"cancelled"` | User dismissed the payment sheet |
| `"Failed"` | Payment attempt failed |

---

## Customizations

The `appearance` option in `PresentPaymentSheetParams` allows you to fully customize the look and feel of the payment sheet to match your app's design.

### Theme

Choose a preset base theme:

```tsx
const options: PresentPaymentSheetParams = {
  appearance: {
    theme: 'Dark', // 'Default' | 'Light' | 'Dark' | 'Minimal' | 'FlatMinimal'
  },
};
```

### Layout

Choose how payment methods are displayed:

```tsx
const options: PresentPaymentSheetParams = {
  appearance: {
    layout: 'tabs', // 'tabs' | 'accordion' | 'spacedAccordion'
  },
};
```

### Colors

Override colors for `light` and/or `dark` mode independently:

```tsx
const options: PresentPaymentSheetParams = {
  appearance: {
    colors: {
      light: {
        primary: '#2563EB',
        background: '#FFFFFF',
        componentBackground: '#F3F4F6',
        componentBorder: '#D1D5DB',
        componentDivider: '#E5E7EB',
        componentText: '#111827',
        primaryText: '#111827',
        secondaryText: '#6B7280',
        placeholderText: '#9CA3AF',
        icon: '#6B7280',
        error: '#EF4444',
      },
      dark: {
        primary: '#3B82F6',
        background: '#111827',
        componentBackground: '#1F2937',
        componentText: '#F9FAFB',
        primaryText: '#F9FAFB',
        secondaryText: '#9CA3AF',
        placeholderText: '#6B7280',
        error: '#F87171',
      },
    },
  },
};
```

#### Available color properties

| Property | Description |
|---|---|
| `primary` | Brand/accent color (buttons, selected borders) |
| `background` | Sheet background color |
| `componentBackground` | Input field and card background color |
| `componentBorder` | Input field border color |
| `componentDivider` | Divider line color |
| `componentText` | Text inside input fields |
| `primaryText` | Heading and label text |
| `secondaryText` | Subtext and helper text |
| `placeholderText` | Placeholder text in input fields |
| `icon` | Icon color |
| `error` | Error message and border color |
| `loaderBackground` | Loading indicator background |
| `loaderForeground` | Loading indicator foreground |

### Shapes

Customize border radius and shadow for UI elements:

```tsx
const options: PresentPaymentSheetParams = {
  appearance: {
    shapes: {
      borderRadius: 8,
      borderWidth: 1.0,
      shadow: {             // iOS only
        color: '#000000',
        opacity: 0.1,
        blurRadius: 8,
        offset: { x: 0, y: 4 },
      },
    },
  },
};
```

### Primary Button

Customize the appearance of the primary action button:

```tsx
const options: PresentPaymentSheetParams = {
  appearance: {
    primaryButton: {
      shapes: {
        borderRadius: 36,
        shadow: {           // iOS only
          color: '#1D4ED8',
          opacity: 0.5,
          blurRadius: 10,
          offset: { x: 0, y: 4 },
        },
      },
      primaryButtonColor: {
        light: {
          background: '#2563EB',
          text: '#FFFFFF',
          border: '#2563EB',
        },
        dark: {
          background: '#1D4ED8',
          text: '#FFFFFF',
          border: '#1D4ED8',
        },
      },
    },
  },
  primaryButtonLabel: 'Complete Purchase',
};
```

### Font

Scale and customize typography:

```tsx
const options: PresentPaymentSheetParams = {
  appearance: {
    font: {
      scale: 1.1,
      headingTextSizeAdjust: 2.0,
      subHeadingTextSizeAdjust: 1.0,
      buttonTextSizeAdjust: 1.0,
      placeholderTextSizeAdjust: 0.0,
    },
  },
};
```

### Google Pay Button

```tsx
const options: PresentPaymentSheetParams = {
  appearance: {
    googlePay: {
      buttonType: 'PAY',            // BUY | BOOK | CHECKOUT | DONATE | ORDER | PAY | SUBSCRIBE | PLAIN
      buttonStyle: {
        light: 'dark',
        dark: 'light',
      },
    },
  },
};
```

### Apple Pay Button

```tsx
const options: PresentPaymentSheetParams = {
  appearance: {
    applePay: {
      buttonType: 'buy',             // 'buy' | 'setUp' | 'inStore' | 'donate' | 'checkout' | 'book' | 'subscribe' | 'plain'
      buttonStyle: {
        light: 'black',
        dark: 'white',
      },
    },
  },
};
```

### Locale

Set the display language for the payment sheet:

```tsx
const options: PresentPaymentSheetParams = {
  appearance: {
    locale: 'En', // En | He | Fr | En_GB | Ar | Ja | De | Es | Pt | It | Pl | Nl | Sv | Ru | ...
  },
};
```

### Full Customization Example

```tsx
import { type PresentPaymentSheetParams } from '@juspay-tech/react-native-hyperswitch';

const paymentOptions: PresentPaymentSheetParams = {
  primaryButtonLabel: 'Complete Purchase',
  merchantDisplayName: 'My Store',
  paymentSheetHeaderText: 'Choose payment method',
  appearance: {
    theme: 'Light',
    layout: 'tabs',
    colors: {
      light: {
        primary: '#2563EB',
        background: '#F9FAFB',
        componentBackground: '#FFFFFF',
        componentText: '#111827',
        primaryText: '#111827',
        secondaryText: '#6B7280',
        error: '#EF4444',
      },
      dark: {
        primary: '#3B82F6',
        background: '#111827',
        componentBackground: '#1F2937',
        componentText: '#F9FAFB',
        primaryText: '#F9FAFB',
        error: '#F87171',
      },
    },
    shapes: {
      borderRadius: 8,
      borderWidth: 1,
    },
    primaryButton: {
      shapes: {
        borderRadius: 36,
      },
      primaryButtonColor: {
        light: { background: '#2563EB', text: '#FFFFFF' },
        dark: { background: '#1D4ED8', text: '#FFFFFF' },
      },
    },
  },
};
```

---

## Payment Widget

The `PaymentWidget` component renders an embedded, inline payment form directly within your screen — without launching a separate modal sheet. It is ideal for checkout pages where you want full layout control.

### Basic Usage

```tsx
import {
  PaymentWidget,
  type PresentPaymentSheetParams,
} from '@juspay-tech/react-native-hyperswitch';

export default function CheckoutScreen() {
  const [clientSecret, setClientSecret] = useState<string | null>(null);

  // Fetch clientSecret from your server and set it in state
  useEffect(() => {
    fetch('https://your-server.com/create-payment-intent', { method: 'POST' })
      .then((res) => res.json())
      .then(({ clientSecret }) => setClientSecret(clientSecret));
  }, []);

  const options: PresentPaymentSheetParams & { clientSecret: string | null } = {
    clientSecret,
    appearance: {
      theme: 'Light',
    },
  };

  return (
    <PaymentWidget
      widgetId="payment-widget"
      widgetType="PAYMENT_SHEET"
      options={options}
      onPaymentResult={(result) => {
        if (result.errorMessage) {
          console.error('Payment failed:', result.errorMessage);
        } else {
          console.log('Payment status:', result.status);
        }
      }}
      style={{ width: '100%', height: 600 }}
    />
  );
}
```

### Props

| Prop | Type | Required | Description |
|---|---|---|---|
| `widgetId` | `string` | ✅ | A unique identifier for the widget instance |
| `widgetType` | `string` | ✅ | Widget type — use `"PAYMENT_SHEET"` |
| `options` | `PresentPaymentSheetParams & { clientSecret?: string \| null }` | ✅ | Appearance and configuration options. Pass `clientSecret` here when using the widget (instead of via `initPaymentSession`) |
| `onPaymentResult` | `(result: PaymentWidgetResult) => void` | ✅ | Callback invoked when the payment completes or fails |
| `style` | `StyleProp<ViewStyle>` | ✅ | Dimensions and positioning for the widget container |

### `onPaymentResult` Callback

The `onPaymentResult` callback receives a result object when the payment flow ends:

```tsx
onPaymentResult={(result) => {
  console.log(result);
  /*
  {
    status?: string;        // e.g. "succeeded", "cancelled", "Failed"
    message?: string;       // Human-readable message
    errorMessage?: string;  // Present when there is an error
    type?: string;          // Error type classification
  }
  */
}}
```

#### Result fields

| Field | Type | Description |
|---|---|---|
| `status` | `string` | Payment outcome: `"succeeded"`, `"cancelled"`, or `"Failed"` |
| `message` | `string` | Human-readable description of the outcome |
| `errorMessage` | `string` | Error details when the payment fails |
| `type` | `string` | Error type classification |

### Handling Widget Results

```tsx
<PaymentWidget
  widgetId="checkout-widget"
  widgetType="PAYMENT_SHEET"
  options={{ clientSecret, appearance: { theme: 'Light' } }}
  onPaymentResult={(result) => {
    if (result.errorMessage) {
      // Payment failed
      console.error('Payment failed:', result.errorMessage);
      setStatus(`Payment failed: ${result.errorMessage}`);
    } else if (result.status === 'succeeded') {
      // Payment succeeded
      console.log('Payment succeeded!');
      setStatus('Payment complete');
    } else if (result.status === 'cancelled') {
      // User cancelled
      setStatus('Payment cancelled');
    }
  }}
  style={{ width: '100%', height: 600 }}
/>
```

### Widget vs. Payment Sheet

| Feature | `presentPaymentSheet()` | `PaymentWidget` |
|---|---|---|
| UI style | Full-screen modal sheet | Embedded inline in your layout |
| Layout control | Limited | Full control via `style` prop |
| Client secret | Passed via `initPaymentSession()` | Passed directly via `options.clientSecret` |
| Result handling | `Promise` return value | `onPaymentResult` callback prop |

---

## API Reference

### `HyperProvider`

```tsx
<HyperProvider publishableKey="pk_snd_...">
  {/* children */}
</HyperProvider>
```

| Prop | Type | Required | Description |
|---|---|---|---|
| `publishableKey` | `string` | ✅ | Your Hyperswitch Publishable Key |

### `useHyper()`

Returns an object with:

```tsx
const { initPaymentSession, presentPaymentSheet } = useHyper();
```

#### `initPaymentSession(params)`

Initializes the payment session with a client secret.

```tsx
const result: InitPaymentSessionResult = await initPaymentSession({
  paymentIntentClientSecret: 'pay_xxx_secret_yyy',
});
```

| Param | Type | Description |
|---|---|---|
| `paymentIntentClientSecret` | `string` | The `client_secret` from your server |

Returns `InitPaymentSessionResult`:

| Field | Type | Description |
|---|---|---|
| `error` | `string` | Error message if initialization failed |

#### `presentPaymentSheet(params)`

Displays the payment sheet modal.

```tsx
const result: PresentPaymentSheetResult = await presentPaymentSheet(options);
```

Returns `PresentPaymentSheetResult`:

| Field | Type | Description |
|---|---|---|
| `error` | `{ code?: string; message?: string }` | Error if payment failed or was cancelled |
| `paymentResult` | `{ status: string; message: string }` | Result when the sheet closes |

### `PresentPaymentSheetParams` (full reference)

| Field | Type | Description |
|---|---|---|
| `appearance` | `AppearanceConfig` | Visual customization options (see Customizations) |
| `primaryButtonLabel` | `string` | Custom label for the pay button |
| `paymentSheetHeaderText` | `string` | Header text on the payment sheet |
| `savedPaymentScreenHeaderText` | `string` | Header text on the saved payments screen |
| `merchantDisplayName` | `string` | Your business name shown to the customer |
| `defaultBillingDetails` | `AddressDetails` | Pre-fill billing address and contact info |
| `shippingDetails` | `AddressDetails` | Pre-fill shipping address |
| `allowsDelayedPaymentMethods` | `boolean` | Allow payment methods that require delayed confirmation |
| `allowsPaymentMethodsRequiringShippingAddress` | `boolean` | Allow methods that need a shipping address |
| `displaySavedPaymentMethods` | `boolean` | Show or hide saved payment methods |
| `displaySavedPaymentMethodsCheckbox` | `boolean` | Show or hide the "save card" checkbox |
| `placeholder` | `{ cardNumber?: string; expiryDate?: string; cvv?: string }` | Custom placeholders for card input fields |
| `defaultView` | `boolean` | Whether to start on the default payment view |
| `clientSecret` | `string` | Client secret (used with `PaymentWidget` instead of `initPaymentSession`) |
| `customer` | `{ id?: string; ephemeralKeySecret?: string }` | Customer association for saved payment methods. `ephemeralKeySecret` is a short-lived key generated server-side that grants the SDK read access to the customer's saved payment methods without exposing your Secret Key. |
| `netceteraSDKApiKey` | `string` | API key for Netcetera 3DS SDK (optional add-on) |

---

## Error Handling

Wrap all payment operations in `try/catch` and handle errors from both `initPaymentSession` and `presentPaymentSheet`:

```tsx
const setup = async () => {
  try {
    const response = await fetch('https://your-server.com/create-payment-intent', {
      method: 'POST',
    });
    const { clientSecret } = await response.json();

    const result = await initPaymentSession({
      paymentIntentClientSecret: clientSecret,
    });

    if (result.error) {
      console.error('Initialization failed:', result.error);
      setStatus('Failed to load payment');
      return;
    }

    setStatus('Ready to pay');
  } catch (error) {
    console.error('Setup error:', error);
    setStatus('Network error');
  }
};

const checkout = async () => {
  try {
    const { error, paymentResult } = await presentPaymentSheet({
      primaryButtonLabel: 'Pay Now',
    });

    if (error) {
      console.error(`Payment error [${error.code}]:`, error.message);
      setStatus('Payment failed');
    } else {
      console.log('Payment result:', paymentResult?.status);
      setStatus('Payment complete');
    }
  } catch (error) {
    console.error('Checkout error:', error);
    setStatus('Unexpected error');
  }
};
```

---

## Troubleshooting

### Common Issues

1. **Metro bundler issues with SVG**
   - Ensure `react-native-svg` is properly installed and linked

2. **Android network requests failing in emulator**
   - Use `http://10.0.2.2:PORT` instead of `http://localhost:PORT` for Android emulator

3. **iOS build issues**
   - Run `cd ios && pod install` after installing the SDK

4. **Payment initialization fails**
   - Verify your publishable key is correct
   - Ensure your backend returns a valid `clientSecret`
   - Check network connectivity

5. **React Native CodeGen issues**
   - Clean the Android builds: `cd android && ./gradlew clean`
   - Re-run `npx react-native codegen` — this step can be skipped for Old Architecture

6. **`useHyper()` throws an error**
   - Ensure the component calling `useHyper()` is rendered inside `<HyperProvider>`

### Debug Tips

- Enable console logging to track the full payment flow
- Verify the `clientSecret` format from your backend (`pay_xxx_secret_yyy`)
- Test with different payment methods
- Check the [Hyperswitch Dashboard](https://app.hyperswitch.io) to inspect payment status

---

## Support

For issues and questions:
- Check the [Hyperswitch documentation](https://hyperswitch.io/docs)
- Review the SDK source code on GitHub
- Contact Hyperswitch support team