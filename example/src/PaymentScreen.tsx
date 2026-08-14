// import { useState, useEffect, useCallback } from 'react';
// import {
//   View,
//   Text,
//   TextInput,
//   TouchableOpacity,
//   ScrollView,
//   ActivityIndicator,
// } from 'react-native';
// import {
//   PaymentWidget,
//   CvcWidget,
//   HyperElements,
//   useWidget,
//   usePaymentSession,
//   type HyperElementsOptions,
//   type HyperInstance,
//   type PaymentEvent,
//   type HeadlessResponse,
//   type SavedPaymentMethod,
// } from '@juspay-tech/react-native-hyperswitch';
// import {
//   initialBaseUrl,
//   getCustomisationOptions,
//   getCvcInputOptions,
//   getStatus,
//   getErrorMessage,
// } from './utils';
// import { styles } from './styles';

// interface UIScreenProps {
//   hyperPromise: Promise<HyperInstance>;
// }

// // Inner component that uses hooks inside HyperElements context
// function UIScreenContent({
//   hyperPromise,
//   baseURL,
//   setBaseURL,
//   sdkAuthorization,
//   setSdkAuthorization,
// }: {
//   hyperPromise: Promise<HyperInstance>;
//   baseURL: string;
//   setBaseURL: (url: string) => void;
//   setSdkAuthorization: (sdkAuthorization: string) => void;
//   sdkAuthorization: string;
// }) {
//   const [status, setStatus] = useState<string>('');
//   const [message, setMessage] = useState<string>('');
//   const [paymentId, setPaymentId] = useState<string>('');
//   const [lastUsedMethod, setLastUsedMethod] =
//     useState<SavedPaymentMethod | null>(null);
//   const [defaultMethod, setDefaultMethod] = useState<SavedPaymentMethod | null>(
//     null
//   );
//   const [loading, setLoading] = useState<boolean>(false);
//   const [sessionInitializing, setSessionInitializing] =
//     useState<boolean>(false);
//   const [paymentCompleted, setPaymentCompleted] = useState<boolean>(false);
//   const [showWidget, setShowWidget] = useState<boolean>(true);

//   const widget = useWidget();
//   const { paymentSession } = usePaymentSession();

//   const createPaymentIntent = useCallback(async (): Promise<{
//     sdkAuthorization: string;
//     paymentId: string;
//   }> => {
//     const response = await fetch(`${baseURL}/create-payment-intent`);
//     const data = await response.json();

//     if (!response.ok) {
//       throw new Error(data.error || 'Failed to create payment intent');
//     }
//     setPaymentId(data.payment_id);

//     return {
//       sdkAuthorization: data.sdkAuthorization,
//       paymentId: data.payment_id,
//     };
//   }, [baseURL]);

//   const updatePaymentIntent = useCallback(async (): Promise<{
//     sdkAuthorization: string;
//   } | undefined> => {
//     console.log('Updating payment intent with ID:', paymentId);
//     const response = await fetch(
//       `${baseURL}/update-payment`,

//       {
//         method: 'POST',
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: JSON.stringify({
//           payment_id: paymentId,
//         }),
//       }
//     );
//     const data = await response.json();

//     if (!response.ok) {
//       // throw new Error(data.error || 'Failed to update payment intent');
//       return
//     }

//     return {
//       sdkAuthorization: data.sdkAuthorization,
//     };
//   }, [baseURL, paymentId]);

//   const updateIntent = useCallback(async (): Promise<void> => {
//     if (!paymentSession) {
//       setStatus('Error');
//       setMessage('Payment session not initialized');
//       return;
//     }

//     try {
//       setLoading(true);
//       const result = await paymentSession.updateIntent(async () => {
//         const data = await updatePaymentIntent();
//         return data?.sdkAuthorization || "";
//       });
//       console.log('Update Intent result:', result);

//       setStatus(getStatus(result?.status));
//       setMessage(result?.message || result?.status);
//     } catch (error) {
//       console.error('Update Intent failed:', error);
//       setStatus('Update Intent Error');
//       setMessage(getErrorMessage(error));
//     } finally {
//       setLoading(false);
//     }
//   }, [paymentSession, updatePaymentIntent]);

//   const checkout = useCallback(async (): Promise<void> => {
//     if (!paymentSession) {
//       setStatus('Error');
//       setMessage('Payment session not initialized');
//       return;
//     }

//     try {
//       setLoading(true);
//       const result = await paymentSession.presentPaymentSheet(
//         {
//           ...getCustomisationOptions(),
//           sdkAuthorization,
//         },
//         null
//       );
//       console.log('Checkout result:', result);

//       setStatus(getStatus(result?.status));
//       setMessage(result?.message || result?.status);
//     } catch (error) {
//       console.error('Checkout failed:', error);
//       setStatus('Checkout Error');
//       setMessage(getErrorMessage(error));
//     } finally {
//       setLoading(false);
//     }
//   }, [paymentSession, sdkAuthorization]);

//   const setup = useCallback(async (): Promise<void> => {
//     try {
//       const { sdkAuthorization } = await createPaymentIntent();
//       setSdkAuthorization(sdkAuthorization);
//       setLastUsedMethod(null);
//       setDefaultMethod(null);
//       setPaymentCompleted(false);
//       setShowWidget(true);
//       setStatus('Ready to checkout');
//       setMessage('');
//     } catch (error) {
//       console.error('Setup failed:', error);
//       setStatus('Setup Error');
//       setMessage(getErrorMessage(error));
//     }
//   }, [createPaymentIntent]);

//   const hideWidgetWithDelay = useCallback(() => {
//     // setPaymentCompleted(true);
//     // setTimeout(() => {
//     //   setShowWidget(false);
//     // }, 500);
//   }, []);

//   const confirmPayment = async (): Promise<void> => {
//     try {
//       setLoading(true);
//       const result = await widget.confirmPayment('payment-widget');
//       console.log('Payment result:', result);

//       setStatus(getStatus(result?.status));
//       setMessage(result?.message || result?.status);
//       if (result?.status === 'succeeded' || result?.status === 'failed') {
//         hideWidgetWithDelay();
//       }
//     } catch (error) {
//       console.error('Payment failed:', error);
//       setStatus('Payment Error');
//       setMessage(getErrorMessage(error));
//     } finally {
//       setLoading(false);
//     }
//   };

//   // Fetch saved methods once paymentSession is available from the hook
//   useEffect(() => {
//     if (!paymentSession || !sdkAuthorization) return;

//     const fetchSavedMethods = async () => {
//       try {
//         setSessionInitializing(true);
//         setStatus('Fetching saved methods...');
//         setMessage('');

//         const [lastUsedResult, defaultResult] = await Promise.all([
//           paymentSession.getCustomerLastUsedPaymentMethodData() as Promise<HeadlessResponse>,
//           paymentSession.getCustomerDefaultSavedPaymentMethodData() as Promise<HeadlessResponse>,
//         ]);

//         if (lastUsedResult.status === 'succeeded' && lastUsedResult.data) {
//           setLastUsedMethod(lastUsedResult.data);
//         } else {
//           setLastUsedMethod(null);
//           console.log(
//             'No last-used method:',
//             lastUsedResult.message || lastUsedResult.code
//           );
//         }

//         if (defaultResult.status === 'succeeded' && defaultResult.data) {
//           setDefaultMethod(defaultResult.data);
//         } else {
//           setDefaultMethod(null);
//           console.log(
//             'No default method:',
//             defaultResult.message || defaultResult.code
//           );
//         }

//         setStatus('Ready — saved methods loaded');
//         setMessage('Session + saved methods initialized');
//       } catch (error) {
//         console.error('Fetch saved methods failed:', error);
//         setStatus('Fetch Error');
//         setMessage(getErrorMessage(error));
//       } finally {
//         setSessionInitializing(false);
//       }
//     };

//     fetchSavedMethods();
//   }, [paymentSession, sdkAuthorization]);

//   useEffect(() => {
//     setup();
//   }, [setup]);

//   const refreshSavedMethods = async () => {
//     if (!paymentSession) {
//       setStatus('Error');
//       setMessage('Session not initialized yet');
//       return;
//     }

//     try {
//       setLoading(true);
//       setStatus('Refreshing saved methods...');

//       const [lastUsedResult, defaultResult] = await Promise.all([
//         paymentSession.getCustomerLastUsedPaymentMethodData() as Promise<HeadlessResponse>,
//         paymentSession.getCustomerDefaultSavedPaymentMethodData() as Promise<HeadlessResponse>,
//       ]);

//       if (lastUsedResult.status === 'succeeded' && lastUsedResult.data) {
//         setLastUsedMethod(lastUsedResult.data);
//       } else {
//         setLastUsedMethod(null);
//       }

//       if (defaultResult.status === 'succeeded' && defaultResult.data) {
//         setDefaultMethod(defaultResult.data);
//       } else {
//         setDefaultMethod(null);
//       }

//       setStatus('Saved methods refreshed');
//       setMessage('Last-used and default methods re-fetched');
//     } catch (error) {
//       console.error('Refresh failed:', error);
//       setStatus('Error');
//       setMessage(getErrorMessage(error));
//     } finally {
//       setLoading(false);
//     }
//   };

//   const confirmWithLastUsed = async () => {
//     if (!paymentSession) {
//       setStatus('Error');
//       setMessage('Please wait for session to initialize');
//       return;
//     }

//     try {
//       setStatus('Confirming with CVC (last used)...');

//       const result =
//         (await paymentSession.confirmWithCustomerLastUsedPaymentMethod(
//           'last-used-card'
//         )) as HeadlessResponse;
//       console.log('Confirm with last used (CVC) result:', result);

//       setStatus(getStatus(result.status));
//       setMessage(result.message || result.status);
//     } catch (error) {
//       console.error('Confirm payment failed:', error);
//       setStatus('Error');
//       setMessage(getErrorMessage(error));
//     } finally {
//       setLoading(false);
//     }
//   };

//   const confirmWithDefault = async () => {
//     if (!paymentSession) {
//       setStatus('Error');
//       setMessage('Please wait for session to initialize');
//       return;
//     }

//     try {
//       setStatus('Confirming with CVC (default)...');

//       const result =
//         (await paymentSession.confirmWithCustomerDefaultPaymentMethod(
//           'default-card'
//         )) as HeadlessResponse;
//       console.log('Confirm with default (CVC) result:', result);

//       setStatus(getStatus(result.status));
//       setMessage(result.message || result.status);
//     } catch (error) {
//       console.error('Confirm payment failed:', error);
//       setStatus('Error');
//       setMessage(getErrorMessage(error));
//     } finally {
//       setLoading(false);
//     }
//   };

//   const renderPaymentMethod = (
//     method: SavedPaymentMethod | null,
//     label: string
//   ) => {
//     if (!method) return null;

//     const { card } = method;

//     return (
//       <View style={styles.methodCard}>
//         <Text style={styles.methodLabel}>{label}</Text>
//         <Text style={styles.methodText}>Type: {method.payment_method_str}</Text>
//         {card && (
//           <>
//             <Text style={styles.methodText}>
//               Card: **** {card.last4_digits}
//             </Text>
//             <Text style={styles.methodText}>Scheme: {card.scheme}</Text>
//             <Text style={styles.methodText}>
//               Holder: {card.card_holder_name}
//             </Text>
//             <Text style={styles.methodText}>
//               Expires: {card.expiry_month}/{card.expiry_year}
//             </Text>
//           </>
//         )}
//         <Text style={styles.methodText}>Last Used: {method.last_used_at}</Text>
//         <Text style={styles.methodText}>
//           Payment Token: {method.payment_token}
//         </Text>
//         {method.default_payment_method_set && (
//           <Text style={styles.defaultBadge}>DEFAULT</Text>
//         )}
//       </View>
//     );
//   };

//   const handlePaymentResult = (result: any) => {
//     console.log('Payment Result from Widget:', result);
//     if (result.errorMessage) {
//       setStatus(`Payment failed: ${result.errorMessage}`);
//       setMessage('');
//       hideWidgetWithDelay();
//     } else {
//       setStatus(getStatus(result?.status));
//       setMessage(result?.status);
//       hideWidgetWithDelay();
//     }
//   };

//   const handlePaymentEvent = (event: PaymentEvent) => {
//     console.log('PaymentWidget Event:', event.eventName, event.payload);
//   };

//   const handleCvcEvent = (widgetId: string) => (event: PaymentEvent) => {
//     console.log(
//       `CvcWidget [${widgetId}] Event:`,
//       event.eventName,
//       event.payload
//     );
//   };

//   const isLoading = loading || sessionInitializing;

//   return (
//     <View style={styles.container}>
//       <Text style={styles.title}>UI Mode</Text>

//       <TextInput
//         style={styles.textInput}
//         placeholder="Enter base URL"
//         value={baseURL}
//         onChangeText={setBaseURL}
//       />

//       <TouchableOpacity style={styles.button} onPress={setup}>
//         <Text style={styles.buttonText}>Reload Client Secret</Text>
//       </TouchableOpacity>
//       <TouchableOpacity style={styles.button} onPress={checkout}>
//         <Text style={styles.buttonText}>Checkout</Text>
//       </TouchableOpacity>
//       <TouchableOpacity style={styles.button} onPress={updateIntent}>
//         <Text style={styles.buttonText}>Update Intent</Text>
//       </TouchableOpacity>

//       <View style={styles.status}>
//         <Text style={styles.statusText}>{status}</Text>
//         {message && <Text style={styles.messageText}>{message}</Text>}
//       </View>

//       {showWidget && (
//         <PaymentWidget
//           widgetId="payment-widget"
//           onPaymentResult={handlePaymentResult}
//           style={{ width: '100%', height: 400 }}
//           options={getCustomisationOptions('accordion')}
//           onPaymentEvent={handlePaymentEvent}
//         />
//       )}

//       {showWidget && (
//         <TouchableOpacity
//           style={[
//             styles.button,
//             styles.confirmButton,
//             loading && styles.buttonDisabled,
//           ]}
//           onPress={confirmPayment}
//           disabled={loading}
//         >
//           <Text style={styles.buttonText}>
//             {loading ? 'Processing...' : 'Confirm Payment'}
//           </Text>
//         </TouchableOpacity>
//       )}

//       <Text style={styles.title}>CVC Widget + Headless</Text>

//       {sessionInitializing && (
//         <View style={styles.status}>
//           <ActivityIndicator size="small" color="#007AFF" />
//           <Text style={styles.statusText}>
//             Auto-initializing session & fetching saved methods...
//           </Text>
//         </View>
//       )}

//       <Text style={styles.statusText}>CVC Widget — Default Card:</Text>
//       {defaultMethod && (
//         <CvcWidget
//           id='default-card'
//           options={{
//             ...getCvcInputOptions(),
//             placeholder: '123',
//           }}
//           style={{ width: '30%', height: 80 }}
//           onChange={handleCvcEvent('default-card')}
//           onFocus={() => console.log('CvcWidget [default-card] Focus')}
//           onBlur={() => console.log('CvcWidget [default-card] Blur')}
//         />
//       )}

//       <Text style={styles.statusText}>CVC Widget — Last Used Card:</Text>
//       {lastUsedMethod && (
//         <CvcWidget
//           id='last-used-card'
//           options={{
//             ...getCvcInputOptions(),
//             placeholder: '456',
//           }}
//           style={{ width: '30%', height: 80 }}
//           onChange={handleCvcEvent('last-used-card')}
//           onFocus={() => console.log('CvcWidget [last-used-card] Focus')}
//           onBlur={() => console.log('CvcWidget [last-used-card] Blur')}
//         />
//       )}
//       <TouchableOpacity
//         style={[styles.button, isLoading && styles.buttonDisabled]}
//         onPress={refreshSavedMethods}
//       >
//         <Text style={styles.buttonText}>
//           {isLoading ? 'Loading...' : 'Refresh Saved Methods'}
//         </Text>
//       </TouchableOpacity>

//       <TouchableOpacity
//         style={[
//           styles.button,
//           styles.confirmButton,
//           isLoading && styles.buttonDisabled,
//         ]}
//         onPress={confirmWithDefault}
//       >
//         <Text style={styles.buttonText}>
//           {isLoading ? 'Processing...' : 'Confirm with Default'}
//         </Text>
//       </TouchableOpacity>

//       <TouchableOpacity
//         style={[
//           styles.button,
//           styles.confirmButton,
//           isLoading && styles.buttonDisabled,
//         ]}
//         onPress={confirmWithLastUsed}
//         disabled={isLoading || !lastUsedMethod}
//       >
//         <Text style={styles.buttonText}>
//           {isLoading ? 'Processing...' : 'Confirm with Last Used'}
//         </Text>
//       </TouchableOpacity>
//       {isLoading && (
//         <ActivityIndicator size="large" color="#007AFF" style={styles.loader} />
//       )}
//     </View>
//   );
// }

// export default function PaymentScreenWithHook({ hyperPromise }: UIScreenProps) {
//   const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
//   const [sdkAuthorization, setSdkAuthorization] = useState<string>('');

//   const hyperElementsOptions: HyperElementsOptions | undefined =
//     sdkAuthorization ? { sdkAuthorization } : undefined;

//   return (
//     <ScrollView contentContainerStyle={styles.scrollContainer}>
//       <HyperElements hyper={hyperPromise} options={hyperElementsOptions}>
//         <UIScreenContent
//           hyperPromise={hyperPromise}
//           baseURL={baseURL}
//           setBaseURL={setBaseURL}
//           sdkAuthorization={sdkAuthorization}
//           setSdkAuthorization={setSdkAuthorization}
//         />
//       </HyperElements>
//     </ScrollView>
//   );
// }
