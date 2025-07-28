import type { statusType } from 'lib/typescript';
import * as React from 'react';
import { StyleSheet, View, Button } from 'react-native';
import {
  checkSamsungPayValidity,
  presentSamsungPayPaymentSheet,
} from '@juspay-tech/react-native-hyperswitch-samsung-pay';

const Space = () => <View style={{ marginTop: 10 }} />;
export default function App() {
  const sessionToken = {
    wallet_name: 'samsung_pay',
    version: '2',
    service_id: 'YOUR_SERVICE_ID',
    order_number: 'paySFQabVDSpil6sXalccuE',
    merchant: {
      name: 'Hyperswitch',
      url: 'hyperswitch-demo-store.netlify.app',
      country_code: 'IN',
    },
    amount: {
      option: 'FORMAT_TOTAL_PRICE_ONLY',
      currency_code: 'USD',
      total: '65.00',
    },
    protocol: 'PROTOCOL3DS',
    allowed_brands: ['visa', 'masterCard', 'amex', 'discover'],
  };

  const obj = JSON.stringify(sessionToken);

  console.log('JSON:', obj);

  return (
    <View style={styles.container}>
      {/* <Button
        title="SamsungPay Init"
        onPress={() =>
          samsungPayInit(serviceId, obj, (status) => {
            console.log(status);
          })
        }
      /> */}
      <Space />
      <Button
        title="Check SPAY Validiity"
        onPress={() =>
          checkSamsungPayValidity(obj, (status: statusType) => {
            console.log(status);
          })
        }
      />
      {/* <Space />
      <Button
        title="Activate Samsung Pay"
        onPress={() =>
          activateSamsungPay((status) => {
            console.log(status);
          })
        }
      /> */}
      {/* <Space />
      <Button
        title="Request Card Info"
        onPress={() =>
          requestCardInfo((status, cardBrands) => {
            console.log(status);
            console.log(cardBrands);
          })
        }
      /> */}
      <Space />
      <Button
        title="Present Samsung Pay Sheet"
        onPress={() =>
          presentSamsungPayPaymentSheet((status: statusType) => {
            console.log(status);
            if (status.message == 'success') {
              const k = JSON.parse(status.message.toString());
              console.log(k);
            }
          })
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
