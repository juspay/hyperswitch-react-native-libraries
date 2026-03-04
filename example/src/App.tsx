import { HyperProvider } from '@juspay-tech/react-native-hyperswitch';
import PaymentScreen from './PaymentScreen';

export default function App() {
  return (
    <HyperProvider
      publishableKey={process.env.HYPERSWITCH_PUBLISHABLE_KEY || ''}
      // hyperOptions={
      //   {
      //     clientSecret : "",
      //     appearance : {
      //       theme: "light",
      //     }
      //   }
      // }
    >
      <PaymentScreen />
    </HyperProvider>
  );
}
