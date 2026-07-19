# @juspay-tech/capacitor-hyperswitch

Hyperswitch SDK bindings for Capacitor Applications

## Install

To use npm

```bash
npm install @juspay-tech/capacitor-hyperswitch
npm install @juspay-tech/capacitor-react-hyperswitch
````

To use yarn

```bash
yarn add @juspay-tech/capacitor-hyperswitch
npm install @juspay-tech/capacitor-react-hyperswitch
```

Sync native files

```bash
npx cap sync
```

## API

<docgen-index>

* [`init(...)`](#init)
* [`elements(...)`](#elements)
* [`createElement(...)`](#createelement)
* [`updateIntent(...)`](#updateintent)
* [`getCustomerSavedPaymentMethods(...)`](#getcustomersavedpaymentmethods)
* [`getCustomerSavedPaymentMethodData(...)`](#getcustomersavedpaymentmethoddata)
* [`getCustomerDefaultSavedPaymentMethodData(...)`](#getcustomerdefaultsavedpaymentmethoddata)
* [`getCustomerLastUsedPaymentMethodData(...)`](#getcustomerlastusedpaymentmethoddata)
* [`confirmWithCustomerDefaultPaymentMethod(...)`](#confirmwithcustomerdefaultpaymentmethod)
* [`confirmWithCustomerLastUsedPaymentMethod(...)`](#confirmwithcustomerlastusedpaymentmethod)
* [`confirmPayment(...)`](#confirmpayment)
* [`resolvePaymentConfirmButtonClick(...)`](#resolvepaymentconfirmbuttonclick)
* [`initPaymentSession(...)`](#initpaymentsession)
* [`presentPaymentSheet(...)`](#presentpaymentsheet)
* [`elementOn(...)`](#elementon)
* [`elementCollapse()`](#elementcollapse)
* [`elementBlur()`](#elementblur)
* [`elementUpdate(...)`](#elementupdate)
* [`elementDestroy()`](#elementdestroy)
* [`elementUnmount()`](#elementunmount)
* [`elementMount(...)`](#elementmount)
* [`elementFocus()`](#elementfocus)
* [`elementClear()`](#elementclear)
* [`addListener('paymentElementEvent', ...)`](#addlistenerpaymentelementevent-)
* [`addListener('cvcWidgetEvent', ...)`](#addlistenercvcwidgetevent-)
* [`addListener('onPaymentResultEvent', ...)`](#addlisteneronpaymentresultevent-)
* [`addListener('onPaymentConfirmButtonClickEvent', ...)`](#addlisteneronpaymentconfirmbuttonclickevent-)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### init(...)

```typescript
init(config: HyperswitchConfiguration) => Promise<void>
```

| Param        | Type                                                                          |
| ------------ | ----------------------------------------------------------------------------- |
| **`config`** | <code><a href="#hyperswitchconfiguration">HyperswitchConfiguration</a></code> |

--------------------


### elements(...)

```typescript
elements(options: { elementsOptions: PaymentSessionConfiguration; }) => Promise<{ handlerId: string; }>
```

| Param         | Type                                                                                                      |
| ------------- | --------------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ elementsOptions: <a href="#paymentsessionconfiguration">PaymentSessionConfiguration</a>; }</code> |

**Returns:** <code>Promise&lt;{ handlerId: string; }&gt;</code>

--------------------


### createElement(...)

```typescript
createElement(options: { type: string; createOptions: PaymentElementOptions | CvcWidgetOptions; }) => Promise<void>
```

| Param         | Type                                                                                                                                                      |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ type: string; createOptions: <a href="#paymentsheetoptions">PaymentSheetOptions</a> \| <a href="#cvcwidgetoptions">CvcWidgetOptions</a>; }</code> |

--------------------


### updateIntent(...)

```typescript
updateIntent(options: PaymentSessionConfiguration) => Promise<void>
```

| Param         | Type                                                                                |
| ------------- | ----------------------------------------------------------------------------------- |
| **`options`** | <code><a href="#paymentsessionconfiguration">PaymentSessionConfiguration</a></code> |

--------------------


### getCustomerSavedPaymentMethods(...)

```typescript
getCustomerSavedPaymentMethods(options?: { configuration?: SavedPaymentMethodsConfiguration | undefined; } | undefined) => Promise<{ handlerId: string; }>
```

| Param         | Type                                                                                                               |
| ------------- | ------------------------------------------------------------------------------------------------------------------ |
| **`options`** | <code>{ configuration?: <a href="#savedpaymentmethodsconfiguration">SavedPaymentMethodsConfiguration</a>; }</code> |

**Returns:** <code>Promise&lt;{ handlerId: string; }&gt;</code>

--------------------


### getCustomerSavedPaymentMethodData(...)

```typescript
getCustomerSavedPaymentMethodData(options: { handlerId: string; }) => Promise<PaymentMethodListData>
```

| Param         | Type                                |
| ------------- | ----------------------------------- |
| **`options`** | <code>{ handlerId: string; }</code> |

**Returns:** <code>Promise&lt;<a href="#paymentmethodlistdata">PaymentMethodListData</a>&gt;</code>

--------------------


### getCustomerDefaultSavedPaymentMethodData(...)

```typescript
getCustomerDefaultSavedPaymentMethodData(options: { handlerId: string; }) => Promise<PaymentMethodData>
```

| Param         | Type                                |
| ------------- | ----------------------------------- |
| **`options`** | <code>{ handlerId: string; }</code> |

**Returns:** <code>Promise&lt;<a href="#paymentmethoddata">PaymentMethodData</a>&gt;</code>

--------------------


### getCustomerLastUsedPaymentMethodData(...)

```typescript
getCustomerLastUsedPaymentMethodData(options: { handlerId: string; }) => Promise<PaymentMethodData>
```

| Param         | Type                                |
| ------------- | ----------------------------------- |
| **`options`** | <code>{ handlerId: string; }</code> |

**Returns:** <code>Promise&lt;<a href="#paymentmethoddata">PaymentMethodData</a>&gt;</code>

--------------------


### confirmWithCustomerDefaultPaymentMethod(...)

```typescript
confirmWithCustomerDefaultPaymentMethod(options: { handlerId: string; }) => Promise<PaymentResult>
```

| Param         | Type                                |
| ------------- | ----------------------------------- |
| **`options`** | <code>{ handlerId: string; }</code> |

**Returns:** <code>Promise&lt;<a href="#paymentresult">PaymentResult</a>&gt;</code>

--------------------


### confirmWithCustomerLastUsedPaymentMethod(...)

```typescript
confirmWithCustomerLastUsedPaymentMethod(options: { handlerId: string; }) => Promise<PaymentResult>
```

| Param         | Type                                |
| ------------- | ----------------------------------- |
| **`options`** | <code>{ handlerId: string; }</code> |

**Returns:** <code>Promise&lt;<a href="#paymentresult">PaymentResult</a>&gt;</code>

--------------------


### confirmPayment(...)

```typescript
confirmPayment(options: { confirmParams: Record<string, Object>; }) => Promise<PaymentResult>
```

| Param         | Type                                                                                                      |
| ------------- | --------------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ confirmParams: <a href="#record">Record</a>&lt;string, <a href="#object">Object</a>&gt;; }</code> |

**Returns:** <code>Promise&lt;<a href="#paymentresult">PaymentResult</a>&gt;</code>

--------------------


### resolvePaymentConfirmButtonClick(...)

```typescript
resolvePaymentConfirmButtonClick(options: { proceed: boolean; }) => Promise<void>
```

| Param         | Type                               |
| ------------- | ---------------------------------- |
| **`options`** | <code>{ proceed: boolean; }</code> |

--------------------


### initPaymentSession(...)

```typescript
initPaymentSession(options: { paymentSessionOptions: PaymentSessionConfiguration; }) => Promise<void>
```

| Param         | Type                                                                                                            |
| ------------- | --------------------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ paymentSessionOptions: <a href="#paymentsessionconfiguration">PaymentSessionConfiguration</a>; }</code> |

--------------------


### presentPaymentSheet(...)

```typescript
presentPaymentSheet(options: { sheetOptions: PaymentSheetOptions; }) => Promise<PaymentResult>
```

| Param         | Type                                                                                   |
| ------------- | -------------------------------------------------------------------------------------- |
| **`options`** | <code>{ sheetOptions: <a href="#paymentsheetoptions">PaymentSheetOptions</a>; }</code> |

**Returns:** <code>Promise&lt;<a href="#paymentresult">PaymentResult</a>&gt;</code>

--------------------


### elementOn(...)

```typescript
elementOn(options: { event: string; }) => Promise<void>
```

| Param         | Type                            |
| ------------- | ------------------------------- |
| **`options`** | <code>{ event: string; }</code> |

--------------------


### elementCollapse()

```typescript
elementCollapse() => Promise<void>
```

--------------------


### elementBlur()

```typescript
elementBlur() => Promise<void>
```

--------------------


### elementUpdate(...)

```typescript
elementUpdate(options: { updateOptions: Record<string, Object>; }) => Promise<void>
```

| Param         | Type                                                                                                      |
| ------------- | --------------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ updateOptions: <a href="#record">Record</a>&lt;string, <a href="#object">Object</a>&gt;; }</code> |

--------------------


### elementDestroy()

```typescript
elementDestroy() => Promise<void>
```

--------------------


### elementUnmount()

```typescript
elementUnmount() => Promise<void>
```

--------------------


### elementMount(...)

```typescript
elementMount(options: { selector: string; }) => Promise<void>
```

| Param         | Type                               |
| ------------- | ---------------------------------- |
| **`options`** | <code>{ selector: string; }</code> |

--------------------


### elementFocus()

```typescript
elementFocus() => Promise<void>
```

--------------------


### elementClear()

```typescript
elementClear() => Promise<void>
```

--------------------


### addListener('paymentElementEvent', ...)

```typescript
addListener(event: 'paymentElementEvent', handler: (data: PaymentEventData) => void) => Promise<{ remove: () => Promise<void>; }>
```

| Param         | Type                                                                             |
| ------------- | -------------------------------------------------------------------------------- |
| **`event`**   | <code>'paymentElementEvent'</code>                                               |
| **`handler`** | <code>(data: <a href="#paymenteventdata">PaymentEventData</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;{ remove: () =&gt; Promise&lt;void&gt;; }&gt;</code>

--------------------


### addListener('cvcWidgetEvent', ...)

```typescript
addListener(event: 'cvcWidgetEvent', handler: (data: PaymentEventData) => void) => Promise<{ remove: () => Promise<void>; }>
```

| Param         | Type                                                                             |
| ------------- | -------------------------------------------------------------------------------- |
| **`event`**   | <code>'cvcWidgetEvent'</code>                                                    |
| **`handler`** | <code>(data: <a href="#paymenteventdata">PaymentEventData</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;{ remove: () =&gt; Promise&lt;void&gt;; }&gt;</code>

--------------------


### addListener('onPaymentResultEvent', ...)

```typescript
addListener(event: 'onPaymentResultEvent', handler: (data: PaymentEventData) => void) => Promise<{ remove: () => Promise<void>; }>
```

| Param         | Type                                                                             |
| ------------- | -------------------------------------------------------------------------------- |
| **`event`**   | <code>'onPaymentResultEvent'</code>                                              |
| **`handler`** | <code>(data: <a href="#paymenteventdata">PaymentEventData</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;{ remove: () =&gt; Promise&lt;void&gt;; }&gt;</code>

--------------------


### addListener('onPaymentConfirmButtonClickEvent', ...)

```typescript
addListener(event: 'onPaymentConfirmButtonClickEvent', handler: (data: PaymentEventData) => void) => Promise<{ remove: () => Promise<void>; }>
```

| Param         | Type                                                                             |
| ------------- | -------------------------------------------------------------------------------- |
| **`event`**   | <code>'onPaymentConfirmButtonClickEvent'</code>                                  |
| **`handler`** | <code>(data: <a href="#paymenteventdata">PaymentEventData</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;{ remove: () =&gt; Promise&lt;void&gt;; }&gt;</code>

--------------------


### Interfaces


#### HyperswitchConfiguration

| Prop                  | Type                                                                                                            |
| --------------------- | --------------------------------------------------------------------------------------------------------------- |
| **`publishableKey`**  | <code>string</code>                                                                                             |
| **`profileId`**       | <code>string</code>                                                                                             |
| **`environment`**     | <code><a href="#hyperswitchenvironment">HyperswitchEnvironment</a></code>                                       |
| **`customEndpoints`** | <code><a href="#commonendpoint">CommonEndpoint</a> \| <a href="#overrideendpoints">OverrideEndpoints</a></code> |


#### CommonEndpoint

| Prop                 | Type                |
| -------------------- | ------------------- |
| **`commonEndpoint`** | <code>string</code> |


#### OverrideEndpoints

| Prop                    | Type                                                                                  |
| ----------------------- | ------------------------------------------------------------------------------------- |
| **`overrideEndpoints`** | <code><a href="#overrideendpontconfiguration">OverrideEndpontConfiguration</a></code> |


#### OverrideEndpontConfiguration

| Prop                          | Type                |
| ----------------------------- | ------------------- |
| **`customBackendEndpoint`**   | <code>string</code> |
| **`customLoggingEndpoint`**   | <code>string</code> |
| **`customAssetEndpoint`**     | <code>string</code> |
| **`customSDKConfigEndpoint`** | <code>string</code> |
| **`customAirborneEndpoint`**  | <code>string</code> |


#### PaymentSessionConfiguration

| Prop                   | Type                |
| ---------------------- | ------------------- |
| **`sdkAuthorization`** | <code>string</code> |


#### CvcWidgetOptions

| Prop                   | Type                                                    |
| ---------------------- | ------------------------------------------------------- |
| **`appearance`**       | <code><a href="#cvcappearance">CvcAppearance</a></code> |
| **`placeholder`**      | <code>string</code>                                     |
| **`sdkAuthorization`** | <code>string</code>                                     |
| **`cvcIcon`**          | <code>'shown' \| 'hidden'</code>                        |


#### CvcAppearance

| Prop         | Type                                                                                       |
| ------------ | ------------------------------------------------------------------------------------------ |
| **`theme`**  | <code><a href="#theme">Theme</a></code>                                                    |
| **`colors`** | <code><a href="#colortype">ColorType</a></code>                                            |
| **`shapes`** | <code><a href="#shapes">Shapes</a></code>                                                  |
| **`font`**   | <code><a href="#pick">Pick</a>&lt;<a href="#font">Font</a>, 'family' \| 'scale'&gt;</code> |


#### ColorType

| Prop        | Type                                      |
| ----------- | ----------------------------------------- |
| **`light`** | <code><a href="#colors">Colors</a></code> |
| **`dark`**  | <code><a href="#colors">Colors</a></code> |


#### Colors

| Prop                               | Type                |
| ---------------------------------- | ------------------- |
| **`primary`**                      | <code>string</code> |
| **`background`**                   | <code>string</code> |
| **`componentBackground`**          | <code>string</code> |
| **`componentBorder`**              | <code>string</code> |
| **`componentDivider`**             | <code>string</code> |
| **`componentText`**                | <code>string</code> |
| **`primaryText`**                  | <code>string</code> |
| **`secondaryText`**                | <code>string</code> |
| **`placeholderText`**              | <code>string</code> |
| **`icon`**                         | <code>string</code> |
| **`error`**                        | <code>string</code> |
| **`loaderBackground`**             | <code>string</code> |
| **`loaderForeground`**             | <code>string</code> |
| **`overlay`**                      | <code>string</code> |
| **`selectedComponentBackground`**  | <code>string</code> |
| **`selectedComponentBorder`**      | <code>string</code> |
| **`selectedComponentBorderWidth`** | <code>number</code> |
| **`selectedComponentDivider`**     | <code>string</code> |
| **`selectedComponentText`**        | <code>string</code> |


#### Shapes

| Prop               | Type                                                  |
| ------------------ | ----------------------------------------------------- |
| **`borderRadius`** | <code>number</code>                                   |
| **`borderWidth`**  | <code>number</code>                                   |
| **`shadow`**       | <code><a href="#shadowconfig">ShadowConfig</a></code> |
| **`inputHeight`**  | <code>number</code>                                   |
| **`gap`**          | <code>number</code>                                   |


#### ShadowConfig

| Prop             | Type                                              |
| ---------------- | ------------------------------------------------- |
| **`color`**      | <code>string</code>                               |
| **`opacity`**    | <code>number</code>                               |
| **`blurRadius`** | <code>number</code>                               |
| **`offset`**     | <code><a href="#offsettype">OffsetType</a></code> |
| **`intensity`**  | <code>number</code>                               |


#### OffsetType

| Prop    | Type                |
| ------- | ------------------- |
| **`x`** | <code>number</code> |
| **`y`** | <code>number</code> |


#### Font

| Prop                            | Type                |
| ------------------------------- | ------------------- |
| **`family`**                    | <code>string</code> |
| **`scale`**                     | <code>number</code> |
| **`headingTextSizeAdjust`**     | <code>number</code> |
| **`subHeadingTextSizeAdjust`**  | <code>number</code> |
| **`placeholderTextSizeAdjust`** | <code>number</code> |
| **`buttonTextSizeAdjust`**      | <code>number</code> |
| **`errorTextSizeAdjust`**       | <code>number</code> |
| **`linkTextSizeAdjust`**        | <code>number</code> |
| **`modalTextSizeAdjust`**       | <code>number</code> |
| **`cardTextSizeAdjust`**        | <code>number</code> |


#### SavedPaymentMethodsConfiguration

| Prop                       | Type                  |
| -------------------------- | --------------------- |
| **`hiddenPaymentMethods`** | <code>string[]</code> |


#### PaymentMethodListData

| Prop        | Type                              |
| ----------- | --------------------------------- |
| **`data`**  | <code>PaymentMethodTypes[]</code> |
| **`error`** | <code>string</code>               |


#### PaymentMethodTypes

| Prop                              | Type                                                    |
| --------------------------------- | ------------------------------------------------------- |
| **`payment_method_type`**         | <code>string</code>                                     |
| **`metadata`**                    | <code>string \| null</code>                             |
| **`default_payment_method_set`**  | <code>boolean</code>                                    |
| **`created`**                     | <code>string</code>                                     |
| **`payment_token`**               | <code>string</code>                                     |
| **`payment_method_issuer_code`**  | <code>string \| null</code>                             |
| **`surcharge_details`**           | <code>string \| null</code>                             |
| **`billing`**                     | <code>string \| null</code>                             |
| **`payment_method_issuer`**       | <code>string</code>                                     |
| **`last_used_at`**                | <code>string</code>                                     |
| **`payment_method_id`**           | <code>string</code>                                     |
| **`bank`**                        | <code>string \| null</code>                             |
| **`installment_payment_enabled`** | <code>boolean</code>                                    |
| **`requires_cvv`**                | <code>boolean</code>                                    |
| **`customer_id`**                 | <code>string</code>                                     |
| **`payment_experience`**          | <code>string[]</code>                                   |
| **`payment_method`**              | <code><a href="#paymentmethod">PaymentMethod</a></code> |
| **`payment_method_str`**          | <code><a href="#paymentmethod">PaymentMethod</a></code> |
| **`card`**                        | <code><a href="#card">Card</a> \| null</code>           |
| **`recurring_enabled`**           | <code>boolean</code>                                    |


#### Card

| Prop                   | Type                        |
| ---------------------- | --------------------------- |
| **`scheme`**           | <code>string</code>         |
| **`last4_digits`**     | <code>string</code>         |
| **`card_holder_name`** | <code>string</code>         |
| **`card_network`**     | <code>string</code>         |
| **`card_type`**        | <code>string</code>         |
| **`expiry_year`**      | <code>string</code>         |
| **`issuer_country`**   | <code>string</code>         |
| **`expiry_month`**     | <code>string</code>         |
| **`card_fingerprint`** | <code>string \| null</code> |
| **`card_issuer`**      | <code>string</code>         |
| **`saved_to_locker`**  | <code>boolean</code>        |
| **`card_token`**       | <code>string \| null</code> |
| **`nick_name`**        | <code>string</code>         |
| **`card_isin`**        | <code>string</code>         |


#### PaymentMethodData

| Prop        | Type                                                                      |
| ----------- | ------------------------------------------------------------------------- |
| **`data`**  | <code><a href="#paymentmethodtypes">PaymentMethodTypes</a> \| null</code> |
| **`error`** | <code>string</code>                                                       |


#### PaymentResult

| Prop          | Type                                               |
| ------------- | -------------------------------------------------- |
| **`type`**    | <code>'completed' \| 'canceled' \| 'failed'</code> |
| **`message`** | <code>string</code>                                |


#### Object

Provides functionality common to all JavaScript objects.

| Prop              | Type                                          | Description                                                                                                                                |
| ----------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **`constructor`** | <code><a href="#function">Function</a></code> | The initial value of <a href="#object">Object</a>.prototype.constructor is the standard built-in <a href="#object">Object</a> constructor. |

| Method                   | Signature                                                 | Description                                                                          |
| ------------------------ | --------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **toString**             | () =&gt; string                                           | Returns a string representation of an object.                                        |
| **toLocaleString**       | () =&gt; string                                           | Returns a date converted to a string using the current <a href="#locale">locale</a>. |
| **valueOf**              | () =&gt; <a href="#object">Object</a>                     | Returns the primitive value of the specified object.                                 |
| **hasOwnProperty**       | (v: <a href="#propertykey">PropertyKey</a>) =&gt; boolean | Determines whether an object has a property with the specified name.                 |
| **isPrototypeOf**        | (v: <a href="#object">Object</a>) =&gt; boolean           | Determines whether an object exists in another object's prototype chain.             |
| **propertyIsEnumerable** | (v: <a href="#propertykey">PropertyKey</a>) =&gt; boolean | Determines whether a specified property is enumerable.                               |


#### Function

Creates a new function.

| Prop            | Type                                          |
| --------------- | --------------------------------------------- |
| **`prototype`** | <code>any</code>                              |
| **`length`**    | <code>number</code>                           |
| **`arguments`** | <code>any</code>                              |
| **`caller`**    | <code><a href="#function">Function</a></code> |

| Method       | Signature                                                                            | Description                                                                                                                                                                                                              |
| ------------ | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **apply**    | (this: <a href="#function">Function</a>, thisArg: any, argArray?: any) =&gt; any     | Calls the function, substituting the specified object for the this value of the function, and the specified array for the arguments of the function.                                                                     |
| **call**     | (this: <a href="#function">Function</a>, thisArg: any, ...argArray: any[]) =&gt; any | Calls a method of an object, substituting another object for the current object.                                                                                                                                         |
| **bind**     | (this: <a href="#function">Function</a>, thisArg: any, ...argArray: any[]) =&gt; any | For a given function, creates a bound function that has the same body as the original function. The this object of the bound function is associated with the specified object, and has the specified initial parameters. |
| **toString** | () =&gt; string                                                                      | Returns a string representation of a function.                                                                                                                                                                           |


#### FunctionDeclaration

| Prop     | Type                                              | Description                                                                                 |
| -------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **`id`** | <code><a href="#identifier">Identifier</a></code> | It is null when a function declaration is a part of the `export default function` statement |


#### Identifier

| Prop       | Type                                                |
| ---------- | --------------------------------------------------- |
| **`type`** | <code>'<a href="#identifier">Identifier</a>'</code> |
| **`name`** | <code>string</code>                                 |


#### FunctionExpression

| Prop       | Type                                                                |
| ---------- | ------------------------------------------------------------------- |
| **`id`**   | <code><a href="#identifier">Identifier</a> \| null</code>           |
| **`type`** | <code>'<a href="#functionexpression">FunctionExpression</a>'</code> |
| **`body`** | <code><a href="#blockstatement">BlockStatement</a></code>           |


#### BlockStatement

| Prop                | Type                                                        |
| ------------------- | ----------------------------------------------------------- |
| **`type`**          | <code>'<a href="#blockstatement">BlockStatement</a>'</code> |
| **`body`**          | <code>Statement[]</code>                                    |
| **`innerComments`** | <code>Comment[]</code>                                      |


#### ExpressionStatement

| Prop             | Type                                                                  |
| ---------------- | --------------------------------------------------------------------- |
| **`type`**       | <code>'<a href="#expressionstatement">ExpressionStatement</a>'</code> |
| **`expression`** | <code><a href="#expression">Expression</a></code>                     |


#### ExpressionMap

| Prop                           | Type                                                                          |
| ------------------------------ | ----------------------------------------------------------------------------- |
| **`ArrayExpression`**          | <code><a href="#arrayexpression">ArrayExpression</a></code>                   |
| **`ArrowFunctionExpression`**  | <code><a href="#arrowfunctionexpression">ArrowFunctionExpression</a></code>   |
| **`AssignmentExpression`**     | <code><a href="#assignmentexpression">AssignmentExpression</a></code>         |
| **`AwaitExpression`**          | <code><a href="#awaitexpression">AwaitExpression</a></code>                   |
| **`BinaryExpression`**         | <code><a href="#binaryexpression">BinaryExpression</a></code>                 |
| **`CallExpression`**           | <code><a href="#callexpression">CallExpression</a></code>                     |
| **`ChainExpression`**          | <code><a href="#chainexpression">ChainExpression</a></code>                   |
| **`ClassExpression`**          | <code><a href="#classexpression">ClassExpression</a></code>                   |
| **`ConditionalExpression`**    | <code><a href="#conditionalexpression">ConditionalExpression</a></code>       |
| **`FunctionExpression`**       | <code><a href="#functionexpression">FunctionExpression</a></code>             |
| **`Identifier`**               | <code><a href="#identifier">Identifier</a></code>                             |
| **`ImportExpression`**         | <code><a href="#importexpression">ImportExpression</a></code>                 |
| **`Literal`**                  | <code><a href="#literal">Literal</a></code>                                   |
| **`LogicalExpression`**        | <code><a href="#logicalexpression">LogicalExpression</a></code>               |
| **`MemberExpression`**         | <code><a href="#memberexpression">MemberExpression</a></code>                 |
| **`MetaProperty`**             | <code><a href="#metaproperty">MetaProperty</a></code>                         |
| **`NewExpression`**            | <code><a href="#newexpression">NewExpression</a></code>                       |
| **`ObjectExpression`**         | <code><a href="#objectexpression">ObjectExpression</a></code>                 |
| **`SequenceExpression`**       | <code><a href="#sequenceexpression">SequenceExpression</a></code>             |
| **`TaggedTemplateExpression`** | <code><a href="#taggedtemplateexpression">TaggedTemplateExpression</a></code> |
| **`TemplateLiteral`**          | <code><a href="#templateliteral">TemplateLiteral</a></code>                   |
| **`ThisExpression`**           | <code><a href="#thisexpression">ThisExpression</a></code>                     |
| **`UnaryExpression`**          | <code><a href="#unaryexpression">UnaryExpression</a></code>                   |
| **`UpdateExpression`**         | <code><a href="#updateexpression">UpdateExpression</a></code>                 |
| **`YieldExpression`**          | <code><a href="#yieldexpression">YieldExpression</a></code>                   |


#### ArrayExpression

| Prop           | Type                                                                                                                                      |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#arrayexpression">ArrayExpression</a>'</code>                                                                             |
| **`elements`** | <code><a href="#array">Array</a>&lt;<a href="#expression">Expression</a> \| <a href="#spreadelement">SpreadElement</a> \| null&gt;</code> |


#### Array

| Prop         | Type                | Description                                                                                            |
| ------------ | ------------------- | ------------------------------------------------------------------------------------------------------ |
| **`length`** | <code>number</code> | Gets or sets the length of the array. This is a number one higher than the highest index in the array. |

| Method             | Signature                                                                                                                     | Description                                                                                                                                                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **toString**       | () =&gt; string                                                                                                               | Returns a string representation of an array.                                                                                                                                                                                                |
| **toLocaleString** | () =&gt; string                                                                                                               | Returns a string representation of an array. The elements are converted to string using their toLocalString methods.                                                                                                                        |
| **pop**            | () =&gt; T \| undefined                                                                                                       | Removes the last element from an array and returns it. If the array is empty, undefined is returned and the array is not modified.                                                                                                          |
| **push**           | (...items: T[]) =&gt; number                                                                                                  | Appends new elements to the end of an array, and returns the new length of the array.                                                                                                                                                       |
| **concat**         | (...items: <a href="#concatarray">ConcatArray</a>&lt;T&gt;[]) =&gt; T[]                                                       | Combines two or more arrays. This method returns a new array without modifying any existing arrays.                                                                                                                                         |
| **concat**         | (...items: (T \| <a href="#concatarray">ConcatArray</a>&lt;T&gt;)[]) =&gt; T[]                                                | Combines two or more arrays. This method returns a new array without modifying any existing arrays.                                                                                                                                         |
| **join**           | (separator?: string \| undefined) =&gt; string                                                                                | Adds all the elements of an array into a string, separated by the specified separator string.                                                                                                                                               |
| **reverse**        | () =&gt; T[]                                                                                                                  | Reverses the elements in an array in place. This method mutates the array and returns a reference to the same array.                                                                                                                        |
| **shift**          | () =&gt; T \| undefined                                                                                                       | Removes the first element from an array and returns it. If the array is empty, undefined is returned and the array is not modified.                                                                                                         |
| **slice**          | (start?: number \| undefined, end?: number \| undefined) =&gt; T[]                                                            | Returns a copy of a section of an array. For both start and end, a negative index can be used to indicate an offset from the end of the array. For example, -2 refers to the second to last element of the array.                           |
| **sort**           | (compareFn?: ((a: T, b: T) =&gt; number) \| undefined) =&gt; this                                                             | Sorts an array in place. This method mutates the array and returns a reference to the same array.                                                                                                                                           |
| **splice**         | (start: number, deleteCount?: number \| undefined) =&gt; T[]                                                                  | Removes elements from an array and, if necessary, inserts new elements in their place, returning the deleted elements.                                                                                                                      |
| **splice**         | (start: number, deleteCount: number, ...items: T[]) =&gt; T[]                                                                 | Removes elements from an array and, if necessary, inserts new elements in their place, returning the deleted elements.                                                                                                                      |
| **unshift**        | (...items: T[]) =&gt; number                                                                                                  | Inserts new elements at the start of an array, and returns the new length of the array.                                                                                                                                                     |
| **indexOf**        | (searchElement: T, fromIndex?: number \| undefined) =&gt; number                                                              | Returns the index of the first occurrence of a value in an array, or -1 if it is not present.                                                                                                                                               |
| **lastIndexOf**    | (searchElement: T, fromIndex?: number \| undefined) =&gt; number                                                              | Returns the index of the last occurrence of a specified value in an array, or -1 if it is not present.                                                                                                                                      |
| **every**          | &lt;S extends T&gt;(predicate: (value: T, index: number, array: T[]) =&gt; value is S, thisArg?: any) =&gt; this is S[]       | Determines whether all the members of an array satisfy the specified test.                                                                                                                                                                  |
| **every**          | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; boolean                                 | Determines whether all the members of an array satisfy the specified test.                                                                                                                                                                  |
| **some**           | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; boolean                                 | Determines whether the specified callback function returns true for any element of an array.                                                                                                                                                |
| **forEach**        | (callbackfn: (value: T, index: number, array: T[]) =&gt; void, thisArg?: any) =&gt; void                                      | Performs the specified action for each element in an array.                                                                                                                                                                                 |
| **map**            | &lt;U&gt;(callbackfn: (value: T, index: number, array: T[]) =&gt; U, thisArg?: any) =&gt; U[]                                 | Calls a defined callback function on each element of an array, and returns an array that contains the results.                                                                                                                              |
| **filter**         | &lt;S extends T&gt;(predicate: (value: T, index: number, array: T[]) =&gt; value is S, thisArg?: any) =&gt; S[]               | Returns the elements of an array that meet the condition specified in a callback function.                                                                                                                                                  |
| **filter**         | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; T[]                                     | Returns the elements of an array that meet the condition specified in a callback function.                                                                                                                                                  |
| **reduce**         | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T) =&gt; T                           | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduce**         | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T, initialValue: T) =&gt; T          |                                                                                                                                                                                                                                             |
| **reduce**         | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: T, currentIndex: number, array: T[]) =&gt; U, initialValue: U) =&gt; U | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduceRight**    | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T) =&gt; T                           | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |
| **reduceRight**    | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T, initialValue: T) =&gt; T          |                                                                                                                                                                                                                                             |
| **reduceRight**    | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: T, currentIndex: number, array: T[]) =&gt; U, initialValue: U) =&gt; U | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |


#### ConcatArray

| Prop         | Type                |
| ------------ | ------------------- |
| **`length`** | <code>number</code> |

| Method    | Signature                                                          |
| --------- | ------------------------------------------------------------------ |
| **join**  | (separator?: string \| undefined) =&gt; string                     |
| **slice** | (start?: number \| undefined, end?: number \| undefined) =&gt; T[] |


#### SpreadElement

| Prop           | Type                                                      |
| -------------- | --------------------------------------------------------- |
| **`type`**     | <code>'<a href="#spreadelement">SpreadElement</a>'</code> |
| **`argument`** | <code><a href="#expression">Expression</a></code>         |


#### ArrowFunctionExpression

| Prop             | Type                                                                                              |
| ---------------- | ------------------------------------------------------------------------------------------------- |
| **`type`**       | <code>'<a href="#arrowfunctionexpression">ArrowFunctionExpression</a>'</code>                     |
| **`expression`** | <code>boolean</code>                                                                              |
| **`body`**       | <code><a href="#expression">Expression</a> \| <a href="#blockstatement">BlockStatement</a></code> |


#### AssignmentExpression

| Prop           | Type                                                                    |
| -------------- | ----------------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#assignmentexpression">AssignmentExpression</a>'</code> |
| **`operator`** | <code><a href="#assignmentoperator">AssignmentOperator</a></code>       |
| **`left`**     | <code><a href="#pattern">Pattern</a></code>                             |
| **`right`**    | <code><a href="#expression">Expression</a></code>                       |


#### ObjectPattern

| Prop             | Type                                                                                                                                          |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **`type`**       | <code>'<a href="#objectpattern">ObjectPattern</a>'</code>                                                                                     |
| **`properties`** | <code><a href="#array">Array</a>&lt;<a href="#assignmentproperty">AssignmentProperty</a> \| <a href="#restelement">RestElement</a>&gt;</code> |


#### AssignmentProperty

| Prop         | Type                                        |
| ------------ | ------------------------------------------- |
| **`value`**  | <code><a href="#pattern">Pattern</a></code> |
| **`kind`**   | <code>'init'</code>                         |
| **`method`** | <code>boolean</code>                        |


#### RestElement

| Prop           | Type                                                  |
| -------------- | ----------------------------------------------------- |
| **`type`**     | <code>'<a href="#restelement">RestElement</a>'</code> |
| **`argument`** | <code><a href="#pattern">Pattern</a></code>           |


#### ArrayPattern

| Prop           | Type                                                                                  |
| -------------- | ------------------------------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#arraypattern">ArrayPattern</a>'</code>                               |
| **`elements`** | <code><a href="#array">Array</a>&lt;<a href="#pattern">Pattern</a> \| null&gt;</code> |


#### AssignmentPattern

| Prop        | Type                                                              |
| ----------- | ----------------------------------------------------------------- |
| **`type`**  | <code>'<a href="#assignmentpattern">AssignmentPattern</a>'</code> |
| **`left`**  | <code><a href="#pattern">Pattern</a></code>                       |
| **`right`** | <code><a href="#expression">Expression</a></code>                 |


#### MemberExpression

| Prop           | Type                                                                                                    |
| -------------- | ------------------------------------------------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#memberexpression">MemberExpression</a>'</code>                                         |
| **`object`**   | <code><a href="#expression">Expression</a> \| <a href="#super">Super</a></code>                         |
| **`property`** | <code><a href="#expression">Expression</a> \| <a href="#privateidentifier">PrivateIdentifier</a></code> |
| **`computed`** | <code>boolean</code>                                                                                    |
| **`optional`** | <code>boolean</code>                                                                                    |


#### Super

| Prop       | Type                                      |
| ---------- | ----------------------------------------- |
| **`type`** | <code>'<a href="#super">Super</a>'</code> |


#### PrivateIdentifier

| Prop       | Type                                                              |
| ---------- | ----------------------------------------------------------------- |
| **`type`** | <code>'<a href="#privateidentifier">PrivateIdentifier</a>'</code> |
| **`name`** | <code>string</code>                                               |


#### AwaitExpression

| Prop           | Type                                                          |
| -------------- | ------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#awaitexpression">AwaitExpression</a>'</code> |
| **`argument`** | <code><a href="#expression">Expression</a></code>             |


#### BinaryExpression

| Prop           | Type                                                                                                    |
| -------------- | ------------------------------------------------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#binaryexpression">BinaryExpression</a>'</code>                                         |
| **`operator`** | <code><a href="#binaryoperator">BinaryOperator</a></code>                                               |
| **`left`**     | <code><a href="#expression">Expression</a> \| <a href="#privateidentifier">PrivateIdentifier</a></code> |
| **`right`**    | <code><a href="#expression">Expression</a></code>                                                       |


#### SimpleCallExpression

| Prop           | Type                                                        |
| -------------- | ----------------------------------------------------------- |
| **`type`**     | <code>'<a href="#callexpression">CallExpression</a>'</code> |
| **`optional`** | <code>boolean</code>                                        |


#### NewExpression

| Prop       | Type                                                      |
| ---------- | --------------------------------------------------------- |
| **`type`** | <code>'<a href="#newexpression">NewExpression</a>'</code> |


#### ChainExpression

| Prop             | Type                                                          |
| ---------------- | ------------------------------------------------------------- |
| **`type`**       | <code>'<a href="#chainexpression">ChainExpression</a>'</code> |
| **`expression`** | <code><a href="#chainelement">ChainElement</a></code>         |


#### ClassExpression

| Prop       | Type                                                          |
| ---------- | ------------------------------------------------------------- |
| **`type`** | <code>'<a href="#classexpression">ClassExpression</a>'</code> |
| **`id`**   | <code><a href="#identifier">Identifier</a> \| null</code>     |


#### ConditionalExpression

| Prop             | Type                                                                      |
| ---------------- | ------------------------------------------------------------------------- |
| **`type`**       | <code>'<a href="#conditionalexpression">ConditionalExpression</a>'</code> |
| **`test`**       | <code><a href="#expression">Expression</a></code>                         |
| **`alternate`**  | <code><a href="#expression">Expression</a></code>                         |
| **`consequent`** | <code><a href="#expression">Expression</a></code>                         |


#### ImportExpression

| Prop          | Type                                                            |
| ------------- | --------------------------------------------------------------- |
| **`type`**    | <code>'<a href="#importexpression">ImportExpression</a>'</code> |
| **`source`**  | <code><a href="#expression">Expression</a></code>               |
| **`options`** | <code><a href="#expression">Expression</a> \| null</code>       |


#### SimpleLiteral

| Prop        | Type                                             |
| ----------- | ------------------------------------------------ |
| **`type`**  | <code>'<a href="#literal">Literal</a>'</code>    |
| **`value`** | <code>string \| number \| boolean \| null</code> |
| **`raw`**   | <code>string</code>                              |


#### RegExpLiteral

| Prop        | Type                                              |
| ----------- | ------------------------------------------------- |
| **`type`**  | <code>'<a href="#literal">Literal</a>'</code>     |
| **`value`** | <code><a href="#regexp">RegExp</a> \| null</code> |
| **`regex`** | <code>{ pattern: string; flags: string; }</code>  |
| **`raw`**   | <code>string</code>                               |


#### RegExp

| Prop             | Type                 | Description                                                                                                                                                          |
| ---------------- | -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`source`**     | <code>string</code>  | Returns a copy of the text of the regular expression pattern. Read-only. The regExp argument is a Regular expression object. It can be a variable name or a literal. |
| **`global`**     | <code>boolean</code> | Returns a Boolean value indicating the state of the global flag (g) used with a regular expression. Default is false. Read-only.                                     |
| **`ignoreCase`** | <code>boolean</code> | Returns a Boolean value indicating the state of the ignoreCase flag (i) used with a regular expression. Default is false. Read-only.                                 |
| **`multiline`**  | <code>boolean</code> | Returns a Boolean value indicating the state of the multiline flag (m) used with a regular expression. Default is false. Read-only.                                  |
| **`lastIndex`**  | <code>number</code>  |                                                                                                                                                                      |

| Method      | Signature                                                                     | Description                                                                                                                   |
| ----------- | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **exec**    | (string: string) =&gt; <a href="#regexpexecarray">RegExpExecArray</a> \| null | Executes a search on a string using a regular expression pattern, and returns an array containing the results of that search. |
| **test**    | (string: string) =&gt; boolean                                                | Returns a Boolean value that indicates whether or not a pattern exists in a searched string.                                  |
| **compile** | () =&gt; this                                                                 |                                                                                                                               |


#### RegExpExecArray

| Prop        | Type                |
| ----------- | ------------------- |
| **`index`** | <code>number</code> |
| **`input`** | <code>string</code> |


#### BigIntLiteral

| Prop         | Type                                          |
| ------------ | --------------------------------------------- |
| **`type`**   | <code>'<a href="#literal">Literal</a>'</code> |
| **`value`**  | <code>bigint \| null</code>                   |
| **`bigint`** | <code>string</code>                           |
| **`raw`**    | <code>string</code>                           |


#### LogicalExpression

| Prop           | Type                                                              |
| -------------- | ----------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#logicalexpression">LogicalExpression</a>'</code> |
| **`operator`** | <code><a href="#logicaloperator">LogicalOperator</a></code>       |
| **`left`**     | <code><a href="#expression">Expression</a></code>                 |
| **`right`**    | <code><a href="#expression">Expression</a></code>                 |


#### MetaProperty

| Prop           | Type                                                    |
| -------------- | ------------------------------------------------------- |
| **`type`**     | <code>'<a href="#metaproperty">MetaProperty</a>'</code> |
| **`meta`**     | <code><a href="#identifier">Identifier</a></code>       |
| **`property`** | <code><a href="#identifier">Identifier</a></code>       |


#### ObjectExpression

| Prop             | Type                                                                                                                          |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **`type`**       | <code>'<a href="#objectexpression">ObjectExpression</a>'</code>                                                               |
| **`properties`** | <code><a href="#array">Array</a>&lt;<a href="#property">Property</a> \| <a href="#spreadelement">SpreadElement</a>&gt;</code> |


#### Property

| Prop            | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`type`**      | <code>'<a href="#property">Property</a>'</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| **`key`**       | <code><a href="#expression">Expression</a> \| <a href="#privateidentifier">PrivateIdentifier</a></code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **`value`**     | <code><a href="#classexpression">ClassExpression</a> \| <a href="#arrayexpression">ArrayExpression</a> \| <a href="#arrowfunctionexpression">ArrowFunctionExpression</a> \| <a href="#assignmentexpression">AssignmentExpression</a> \| <a href="#awaitexpression">AwaitExpression</a> \| <a href="#binaryexpression">BinaryExpression</a> \| <a href="#simplecallexpression">SimpleCallExpression</a> \| <a href="#newexpression">NewExpression</a> \| <a href="#chainexpression">ChainExpression</a> \| <a href="#conditionalexpression">ConditionalExpression</a> \| <a href="#functionexpression">FunctionExpression</a> \| <a href="#identifier">Identifier</a> \| <a href="#importexpression">ImportExpression</a> \| <a href="#simpleliteral">SimpleLiteral</a> \| <a href="#regexpliteral">RegExpLiteral</a> \| <a href="#bigintliteral">BigIntLiteral</a> \| <a href="#logicalexpression">LogicalExpression</a> \| <a href="#memberexpression">MemberExpression</a> \| <a href="#metaproperty">MetaProperty</a> \| <a href="#objectexpression">ObjectExpression</a> \| <a href="#sequenceexpression">SequenceExpression</a> \| <a href="#taggedtemplateexpression">TaggedTemplateExpression</a> \| <a href="#templateliteral">TemplateLiteral</a> \| <a href="#thisexpression">ThisExpression</a> \| <a href="#unaryexpression">UnaryExpression</a> \| <a href="#updateexpression">UpdateExpression</a> \| <a href="#yieldexpression">YieldExpression</a> \| <a href="#objectpattern">ObjectPattern</a> \| <a href="#arraypattern">ArrayPattern</a> \| <a href="#restelement">RestElement</a> \| <a href="#assignmentpattern">AssignmentPattern</a></code> |
| **`kind`**      | <code>'init' \| 'get' \| 'set'</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| **`method`**    | <code>boolean</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| **`shorthand`** | <code>boolean</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| **`computed`**  | <code>boolean</code>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |


#### SequenceExpression

| Prop              | Type                                                                |
| ----------------- | ------------------------------------------------------------------- |
| **`type`**        | <code>'<a href="#sequenceexpression">SequenceExpression</a>'</code> |
| **`expressions`** | <code>Expression[]</code>                                           |


#### TaggedTemplateExpression

| Prop        | Type                                                                            |
| ----------- | ------------------------------------------------------------------------------- |
| **`type`**  | <code>'<a href="#taggedtemplateexpression">TaggedTemplateExpression</a>'</code> |
| **`tag`**   | <code><a href="#expression">Expression</a></code>                               |
| **`quasi`** | <code><a href="#templateliteral">TemplateLiteral</a></code>                     |


#### TemplateLiteral

| Prop              | Type                                                          |
| ----------------- | ------------------------------------------------------------- |
| **`type`**        | <code>'<a href="#templateliteral">TemplateLiteral</a>'</code> |
| **`quasis`**      | <code>TemplateElement[]</code>                                |
| **`expressions`** | <code>Expression[]</code>                                     |


#### TemplateElement

| Prop        | Type                                                          |
| ----------- | ------------------------------------------------------------- |
| **`type`**  | <code>'<a href="#templateelement">TemplateElement</a>'</code> |
| **`tail`**  | <code>boolean</code>                                          |
| **`value`** | <code>{ cooked?: string \| null; raw: string; }</code>        |


#### ThisExpression

| Prop       | Type                                                        |
| ---------- | ----------------------------------------------------------- |
| **`type`** | <code>'<a href="#thisexpression">ThisExpression</a>'</code> |


#### UnaryExpression

| Prop           | Type                                                          |
| -------------- | ------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#unaryexpression">UnaryExpression</a>'</code> |
| **`operator`** | <code><a href="#unaryoperator">UnaryOperator</a></code>       |
| **`prefix`**   | <code>true</code>                                             |
| **`argument`** | <code><a href="#expression">Expression</a></code>             |


#### UpdateExpression

| Prop           | Type                                                            |
| -------------- | --------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#updateexpression">UpdateExpression</a>'</code> |
| **`operator`** | <code><a href="#updateoperator">UpdateOperator</a></code>       |
| **`argument`** | <code><a href="#expression">Expression</a></code>               |
| **`prefix`**   | <code>boolean</code>                                            |


#### YieldExpression

| Prop           | Type                                                          |
| -------------- | ------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#yieldexpression">YieldExpression</a>'</code> |
| **`argument`** | <code><a href="#expression">Expression</a> \| null</code>     |
| **`delegate`** | <code>boolean</code>                                          |


#### StaticBlock

| Prop       | Type                                                  |
| ---------- | ----------------------------------------------------- |
| **`type`** | <code>'<a href="#staticblock">StaticBlock</a>'</code> |


#### EmptyStatement

| Prop       | Type                                                        |
| ---------- | ----------------------------------------------------------- |
| **`type`** | <code>'<a href="#emptystatement">EmptyStatement</a>'</code> |


#### DebuggerStatement

| Prop       | Type                                                              |
| ---------- | ----------------------------------------------------------------- |
| **`type`** | <code>'<a href="#debuggerstatement">DebuggerStatement</a>'</code> |


#### WithStatement

| Prop         | Type                                                      |
| ------------ | --------------------------------------------------------- |
| **`type`**   | <code>'<a href="#withstatement">WithStatement</a>'</code> |
| **`object`** | <code><a href="#expression">Expression</a></code>         |
| **`body`**   | <code><a href="#statement">Statement</a></code>           |


#### ReturnStatement

| Prop           | Type                                                          |
| -------------- | ------------------------------------------------------------- |
| **`type`**     | <code>'<a href="#returnstatement">ReturnStatement</a>'</code> |
| **`argument`** | <code><a href="#expression">Expression</a> \| null</code>     |


#### LabeledStatement

| Prop        | Type                                                            |
| ----------- | --------------------------------------------------------------- |
| **`type`**  | <code>'<a href="#labeledstatement">LabeledStatement</a>'</code> |
| **`label`** | <code><a href="#identifier">Identifier</a></code>               |
| **`body`**  | <code><a href="#statement">Statement</a></code>                 |


#### BreakStatement

| Prop        | Type                                                        |
| ----------- | ----------------------------------------------------------- |
| **`type`**  | <code>'<a href="#breakstatement">BreakStatement</a>'</code> |
| **`label`** | <code><a href="#identifier">Identifier</a> \| null</code>   |


#### ContinueStatement

| Prop        | Type                                                              |
| ----------- | ----------------------------------------------------------------- |
| **`type`**  | <code>'<a href="#continuestatement">ContinueStatement</a>'</code> |
| **`label`** | <code><a href="#identifier">Identifier</a> \| null</code>         |


#### IfStatement

| Prop             | Type                                                    |
| ---------------- | ------------------------------------------------------- |
| **`type`**       | <code>'<a href="#ifstatement">IfStatement</a>'</code>   |
| **`test`**       | <code><a href="#expression">Expression</a></code>       |
| **`consequent`** | <code><a href="#statement">Statement</a></code>         |
| **`alternate`**  | <code><a href="#statement">Statement</a> \| null</code> |


#### SwitchStatement

| Prop               | Type                                                          |
| ------------------ | ------------------------------------------------------------- |
| **`type`**         | <code>'<a href="#switchstatement">SwitchStatement</a>'</code> |
| **`discriminant`** | <code><a href="#expression">Expression</a></code>             |
| **`cases`**        | <code>SwitchCase[]</code>                                     |


#### SwitchCase

| Prop             | Type                                                      |
| ---------------- | --------------------------------------------------------- |
| **`type`**       | <code>'<a href="#switchcase">SwitchCase</a>'</code>       |
| **`test`**       | <code><a href="#expression">Expression</a> \| null</code> |
| **`consequent`** | <code>Statement[]</code>                                  |


#### ThrowStatement

| Prop           | Type                                                        |
| -------------- | ----------------------------------------------------------- |
| **`type`**     | <code>'<a href="#throwstatement">ThrowStatement</a>'</code> |
| **`argument`** | <code><a href="#expression">Expression</a></code>           |


#### TryStatement

| Prop            | Type                                                              |
| --------------- | ----------------------------------------------------------------- |
| **`type`**      | <code>'<a href="#trystatement">TryStatement</a>'</code>           |
| **`block`**     | <code><a href="#blockstatement">BlockStatement</a></code>         |
| **`handler`**   | <code><a href="#catchclause">CatchClause</a> \| null</code>       |
| **`finalizer`** | <code><a href="#blockstatement">BlockStatement</a> \| null</code> |


#### CatchClause

| Prop        | Type                                                      |
| ----------- | --------------------------------------------------------- |
| **`type`**  | <code>'<a href="#catchclause">CatchClause</a>'</code>     |
| **`param`** | <code><a href="#pattern">Pattern</a> \| null</code>       |
| **`body`**  | <code><a href="#blockstatement">BlockStatement</a></code> |


#### WhileStatement

| Prop       | Type                                                        |
| ---------- | ----------------------------------------------------------- |
| **`type`** | <code>'<a href="#whilestatement">WhileStatement</a>'</code> |
| **`test`** | <code><a href="#expression">Expression</a></code>           |
| **`body`** | <code><a href="#statement">Statement</a></code>             |


#### DoWhileStatement

| Prop       | Type                                                            |
| ---------- | --------------------------------------------------------------- |
| **`type`** | <code>'<a href="#dowhilestatement">DoWhileStatement</a>'</code> |
| **`body`** | <code><a href="#statement">Statement</a></code>                 |
| **`test`** | <code><a href="#expression">Expression</a></code>               |


#### ForStatement

| Prop         | Type                                                                                                                |
| ------------ | ------------------------------------------------------------------------------------------------------------------- |
| **`type`**   | <code>'<a href="#forstatement">ForStatement</a>'</code>                                                             |
| **`init`**   | <code><a href="#expression">Expression</a> \| <a href="#variabledeclaration">VariableDeclaration</a> \| null</code> |
| **`test`**   | <code><a href="#expression">Expression</a> \| null</code>                                                           |
| **`update`** | <code><a href="#expression">Expression</a> \| null</code>                                                           |
| **`body`**   | <code><a href="#statement">Statement</a></code>                                                                     |


#### VariableDeclaration

| Prop               | Type                                                                  |
| ------------------ | --------------------------------------------------------------------- |
| **`type`**         | <code>'<a href="#variabledeclaration">VariableDeclaration</a>'</code> |
| **`declarations`** | <code>VariableDeclarator[]</code>                                     |
| **`kind`**         | <code>'var' \| 'let' \| 'const' \| 'using' \| 'await using'</code>    |


#### VariableDeclarator

| Prop       | Type                                                                |
| ---------- | ------------------------------------------------------------------- |
| **`type`** | <code>'<a href="#variabledeclarator">VariableDeclarator</a>'</code> |
| **`id`**   | <code><a href="#pattern">Pattern</a></code>                         |
| **`init`** | <code><a href="#expression">Expression</a> \| null</code>           |


#### ForInStatement

| Prop       | Type                                                        |
| ---------- | ----------------------------------------------------------- |
| **`type`** | <code>'<a href="#forinstatement">ForInStatement</a>'</code> |


#### ForOfStatement

| Prop        | Type                                                        |
| ----------- | ----------------------------------------------------------- |
| **`type`**  | <code>'<a href="#forofstatement">ForOfStatement</a>'</code> |
| **`await`** | <code>boolean</code>                                        |


#### ClassDeclaration

| Prop     | Type                                              | Description                                                                           |
| -------- | ------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **`id`** | <code><a href="#identifier">Identifier</a></code> | It is null when a class declaration is a part of the `export default class` statement |


#### Comment

| Prop        | Type                           |
| ----------- | ------------------------------ |
| **`type`**  | <code>'Line' \| 'Block'</code> |
| **`value`** | <code>string</code>            |


#### PaymentSheetOptions

| Prop                                               | Type                                                                              |
| -------------------------------------------------- | --------------------------------------------------------------------------------- |
| **`sdkAuthorization`**                             | <code>string</code>                                                               |
| **`allowsDelayedPaymentMethods`**                  | <code>boolean</code>                                                              |
| **`appearance`**                                   | <code><a href="#appearance">Appearance</a></code>                                 |
| **`shippingDetails`**                              | <code><a href="#addressdetails">AddressDetails</a></code>                         |
| **`primaryButtonLabel`**                           | <code>string</code>                                                               |
| **`paymentSheetHeaderText`**                       | <code>string</code>                                                               |
| **`savedPaymentScreenHeaderText`**                 | <code>string</code>                                                               |
| **`merchantDisplayName`**                          | <code>string</code>                                                               |
| **`billingDetails`**                               | <code><a href="#addressdetails">AddressDetails</a></code>                         |
| **`primaryButtonColor`**                           | <code>string</code>                                                               |
| **`allowsPaymentMethodsRequiringShippingAddress`** | <code>boolean</code>                                                              |
| **`displaySavedPaymentMethodsCheckbox`**           | <code>boolean</code>                                                              |
| **`displaySavedPaymentMethods`**                   | <code>boolean</code>                                                              |
| **`displayPayButton`**                             | <code>boolean</code>                                                              |
| **`placeholder`**                                  | <code><a href="#placeholder">Placeholder</a></code>                               |
| **`defaultView`**                                  | <code>boolean</code>                                                              |
| **`disableBranding`**                              | <code>boolean</code>                                                              |
| **`netceteraSDKApiKey`**                           | <code>string</code>                                                               |
| **`displayDefaultSavedPaymentIcon`**               | <code>boolean</code>                                                              |
| **`enablePartialLoading`**                         | <code>boolean</code>                                                              |
| **`customer`**                                     | <code><a href="#customerconfiguration">CustomerConfiguration</a></code>           |
| **`paymentSheetHeaderLabel`**                      | <code>string</code>                                                               |
| **`savedPaymentSheetHeaderLabel`**                 | <code>string</code>                                                               |
| **`subscribedEvents`**                             | <code>SubscriptionEvent[]</code>                                                  |
| **`hideConfirmButton`**                            | <code>boolean</code>                                                              |
| **`locale`**                                       | <code><a href="#locale">locale</a></code>                                         |
| **`redirectionInfo`**                              | <code><a href="#redirectioninfo">RedirectionInfo</a></code>                       |
| **`stickyPayButton`**                              | <code>boolean</code>                                                              |
| **`paymentMethodLayout`**                          | <code><a href="#paymentmethodlayout">PaymentMethodLayout</a></code>               |
| **`walletButtonsConfiguration`**                   | <code><a href="#walletbuttonsconfiguration">WalletButtonsConfiguration</a></code> |
| **`paymentMethodsConfig`**                         | <code>PaymentMethodConfig[]</code>                                                |
| **`paymentMethodOrder`**                           | <code>string[]</code>                                                             |
| **`preloadCardElement`**                           | <code>boolean</code>                                                              |
| **`alwaysSendCustomerAcceptance`**                 | <code>boolean</code>                                                              |
| **`opensCardScannerAutomatically`**                | <code>boolean</code>                                                              |
| **`splitCardFields`**                              | <code>boolean</code>                                                              |


#### Appearance

| Prop                | Type                                                            |
| ------------------- | --------------------------------------------------------------- |
| **`theme`**         | <code><a href="#theme">Theme</a></code>                         |
| **`colors`**        | <code><a href="#colortype">ColorType</a></code>                 |
| **`shapes`**        | <code><a href="#shapes">Shapes</a></code>                       |
| **`font`**          | <code><a href="#font">Font</a></code>                           |
| **`primaryButton`** | <code><a href="#primarybutton">PrimaryButton</a></code>         |
| **`logo`**          | <code><a href="#logocustomization">LogoCustomization</a></code> |


#### PrimaryButton

| Prop         | Type                                                                      |
| ------------ | ------------------------------------------------------------------------- |
| **`shapes`** | <code><a href="#shapes">Shapes</a></code>                                 |
| **`colors`** | <code><a href="#primarybuttoncolortype">PrimaryButtonColorType</a></code> |
| **`height`** | <code>number</code>                                                       |


#### PrimaryButtonColorType

| Prop        | Type                                                                |
| ----------- | ------------------------------------------------------------------- |
| **`light`** | <code><a href="#primarybuttoncolors">PrimaryButtonColors</a></code> |
| **`dark`**  | <code><a href="#primarybuttoncolors">PrimaryButtonColors</a></code> |


#### PrimaryButtonColors

| Prop             | Type                |
| ---------------- | ------------------- |
| **`background`** | <code>string</code> |
| **`text`**       | <code>string</code> |
| **`border`**     | <code>string</code> |


#### LogoCustomization

| Prop                          | Type                                                                        |
| ----------------------------- | --------------------------------------------------------------------------- |
| **`borderRadius`**            | <code>number</code>                                                         |
| **`colors`**                  | <code><a href="#logocolortype">LogoColorType</a></code>                     |
| **`checkedIconForSelection`** | <code><a href="#checkediconforselection">CheckedIconForSelection</a></code> |


#### LogoColorType

| Prop        | Type                                              |
| ----------- | ------------------------------------------------- |
| **`light`** | <code><a href="#logocolors">LogoColors</a></code> |
| **`dark`**  | <code><a href="#logocolors">LogoColors</a></code> |


#### LogoColors

| Prop                  | Type                |
| --------------------- | ------------------- |
| **`backgroundColor`** | <code>string</code> |
| **`selected`**        | <code>string</code> |
| **`unselected`**      | <code>string</code> |


#### CheckedIconForSelection

| Prop         | Type                                                                  |
| ------------ | --------------------------------------------------------------------- |
| **`colors`** | <code><a href="#checkediconcolortype">CheckedIconColorType</a></code> |
| **`size`**   | <code>number</code>                                                   |
| **`bottom`** | <code>number</code>                                                   |
| **`right`**  | <code>number</code>                                                   |


#### CheckedIconColorType

| Prop        | Type                                                            |
| ----------- | --------------------------------------------------------------- |
| **`light`** | <code><a href="#checkediconcolors">CheckedIconColors</a></code> |
| **`dark`**  | <code><a href="#checkediconcolors">CheckedIconColors</a></code> |


#### CheckedIconColors

| Prop         | Type                |
| ------------ | ------------------- |
| **`color`**  | <code>string</code> |
| **`stroke`** | <code>string</code> |


#### AddressDetails

| Prop          | Type                                        |
| ------------- | ------------------------------------------- |
| **`address`** | <code><a href="#address">Address</a></code> |
| **`email`**   | <code>string</code>                         |
| **`phone`**   | <code><a href="#phone">Phone</a></code>     |


#### Address

| Prop             | Type                |
| ---------------- | ------------------- |
| **`first_name`** | <code>string</code> |
| **`last_name`**  | <code>string</code> |
| **`city`**       | <code>string</code> |
| **`country`**    | <code>string</code> |
| **`line1`**      | <code>string</code> |
| **`line2`**      | <code>string</code> |
| **`line3`**      | <code>string</code> |
| **`postalCode`** | <code>string</code> |
| **`state`**      | <code>string</code> |


#### Phone

| Prop         | Type                |
| ------------ | ------------------- |
| **`number`** | <code>string</code> |
| **`code`**   | <code>string</code> |


#### Placeholder

| Prop             | Type                |
| ---------------- | ------------------- |
| **`cardNumber`** | <code>string</code> |
| **`expiryDate`** | <code>string</code> |
| **`cvv`**        | <code>string</code> |


#### CustomerConfiguration

| Prop                     | Type                |
| ------------------------ | ------------------- |
| **`id`**                 | <code>string</code> |
| **`ephemeralKeySecret`** | <code>string</code> |


#### PaymentMethodLayout

| Prop                                   | Type                                                                            |
| -------------------------------------- | ------------------------------------------------------------------------------- |
| **`type`**                             | <code><a href="#layouttype">LayoutType</a></code>                               |
| **`showOneClickWalletsOnTop`**         | <code>boolean</code>                                                            |
| **`paymentMethodsArrangementForTabs`** | <code><a href="#paymentmethodsarrangement">PaymentMethodsArrangement</a></code> |
| **`defaultCollapsed`**                 | <code>boolean</code>                                                            |
| **`radios`**                           | <code>boolean</code>                                                            |
| **`spacedAccordionItems`**             | <code>boolean</code>                                                            |
| **`maxAccordionItems`**                | <code>number</code>                                                             |
| **`cvcIcon`**                          | <code><a href="#cvcicondisplay">CvcIconDisplay</a></code>                       |
| **`cardBrandIcon`**                    | <code><a href="#cardbrandicondisplay">CardBrandIconDisplay</a></code>           |
| **`showCheckedIconForSelection`**      | <code>boolean</code>                                                            |
| **`savedMethodCustomization`**         | <code><a href="#savedmethodcustomization">SavedMethodCustomization</a></code>   |


#### SavedMethodCustomization

| Prop                       | Type                                                          |
| -------------------------- | ------------------------------------------------------------- |
| **`defaultCollapsed`**     | <code>boolean</code>                                          |
| **`hideCardExpiry`**       | <code>boolean</code>                                          |
| **`hideCVCError`**         | <code>boolean</code>                                          |
| **`cvcIcon`**              | <code><a href="#cvcicondisplay">CvcIconDisplay</a></code>     |
| **`groupingBehavior`**     | <code><a href="#groupingbehavior">GroupingBehavior</a></code> |
| **`hiddenPaymentMethods`** | <code>string[]</code>                                         |


#### GroupingBehavior

| Prop                           | Type                 |
| ------------------------------ | -------------------- |
| **`displayInSeparateScreen`**  | <code>boolean</code> |
| **`displayInSeparateSection`** | <code>boolean</code> |
| **`groupByPaymentMethods`**    | <code>boolean</code> |


#### WalletButtonsConfiguration

| Prop            | Type                                                                      |
| --------------- | ------------------------------------------------------------------------- |
| **`googlePay`** | <code><a href="#googlepayconfiguration">GooglePayConfiguration</a></code> |
| **`applePay`**  | <code><a href="#applepayconfiguration">ApplePayConfiguration</a></code>   |
| **`payPal`**    | <code><a href="#paypalconfiguration">PayPalConfiguration</a></code>       |


#### GooglePayConfiguration

| Prop              | Type                                                                        |
| ----------------- | --------------------------------------------------------------------------- |
| **`visibility`**  | <code>'shown' \| 'hidden'</code>                                            |
| **`buttonType`**  | <code><a href="#googlepaybuttontype">GooglePayButtonType</a></code>         |
| **`buttonStyle`** | <code><a href="#googlepaythemebasestyle">GooglePayThemeBaseStyle</a></code> |


#### GooglePayThemeBaseStyle

| Prop        | Type                                                                  |
| ----------- | --------------------------------------------------------------------- |
| **`light`** | <code><a href="#googlepaybuttonstyle">GooglePayButtonStyle</a></code> |
| **`dark`**  | <code><a href="#googlepaybuttonstyle">GooglePayButtonStyle</a></code> |


#### ApplePayConfiguration

| Prop              | Type                                                                      |
| ----------------- | ------------------------------------------------------------------------- |
| **`visibility`**  | <code>'shown' \| 'hidden'</code>                                          |
| **`buttonType`**  | <code><a href="#applepaybuttontype">ApplePayButtonType</a></code>         |
| **`buttonStyle`** | <code><a href="#applepaythemebasestyle">ApplePayThemeBaseStyle</a></code> |


#### ApplePayThemeBaseStyle

| Prop        | Type                                                                |
| ----------- | ------------------------------------------------------------------- |
| **`light`** | <code><a href="#applepaybuttonstyle">ApplePayButtonStyle</a></code> |
| **`dark`**  | <code><a href="#applepaybuttonstyle">ApplePayButtonStyle</a></code> |


#### PayPalConfiguration

| Prop              | Type                                                                  |
| ----------------- | --------------------------------------------------------------------- |
| **`visibility`**  | <code>'shown' \| 'hidden'</code>                                      |
| **`buttonType`**  | <code><a href="#paypalbuttontype">PayPalButtonType</a></code>         |
| **`buttonStyle`** | <code><a href="#paypalthemebasestyle">PayPalThemeBaseStyle</a></code> |


#### PayPalThemeBaseStyle

| Prop        | Type                                                            |
| ----------- | --------------------------------------------------------------- |
| **`light`** | <code><a href="#paypalbuttonstyle">PayPalButtonStyle</a></code> |
| **`dark`**  | <code><a href="#paypalbuttonstyle">PayPalButtonStyle</a></code> |


#### PaymentMethodConfig

| Prop                | Type                |
| ------------------- | ------------------- |
| **`paymentMethod`** | <code>string</code> |
| **`message`**       | <code>string</code> |


#### PaymentEventData

| Prop          | Type                                                            |
| ------------- | --------------------------------------------------------------- |
| **`type`**    | <code>string</code>                                             |
| **`payload`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> |


### Type Aliases


#### HyperswitchEnvironment

<code>'sandbox' | 'production'</code>


#### Theme

<code>'Default' | 'Light' | 'Dark' | 'Minimal' | 'FlatMinimal' | 'Brutal' | 'Glass' | 'Skeu' | 'Clay' | 'Charcoal' | 'Soft'</code>


#### Pick

From T, pick a set of properties whose keys are in the union K

<code>{
 [P in K]: T[P];
 }</code>


#### PaymentMethod

<code>'card' | 'wallet' | 'card_redirect' | 'pay_later' | 'bank_redirect' | 'open_banking' | 'bank_debit' | 'bank_transfer' | 'crypto' | 'reward' | 'gift_card' | string</code>


#### Record

Construct a type with a set of properties K of type T

<code>{
 [P in K]: T;
 }</code>


#### PropertyKey

<code>string | number | symbol</code>


#### Function

<code><a href="#functiondeclaration">FunctionDeclaration</a> | <a href="#functionexpression">FunctionExpression</a> | <a href="#arrowfunctionexpression">ArrowFunctionExpression</a></code>


#### Statement

<code><a href="#expressionstatement">ExpressionStatement</a> | <a href="#blockstatement">BlockStatement</a> | <a href="#staticblock">StaticBlock</a> | <a href="#emptystatement">EmptyStatement</a> | <a href="#debuggerstatement">DebuggerStatement</a> | <a href="#withstatement">WithStatement</a> | <a href="#returnstatement">ReturnStatement</a> | <a href="#labeledstatement">LabeledStatement</a> | <a href="#breakstatement">BreakStatement</a> | <a href="#continuestatement">ContinueStatement</a> | <a href="#ifstatement">IfStatement</a> | <a href="#switchstatement">SwitchStatement</a> | <a href="#throwstatement">ThrowStatement</a> | <a href="#trystatement">TryStatement</a> | <a href="#whilestatement">WhileStatement</a> | <a href="#dowhilestatement">DoWhileStatement</a> | <a href="#forstatement">ForStatement</a> | <a href="#forinstatement">ForInStatement</a> | <a href="#forofstatement">ForOfStatement</a> | <a href="#declaration">Declaration</a></code>


#### Expression

<code>ExpressionMap[keyof ExpressionMap]</code>


#### AssignmentOperator

<code>"=" | "+=" | "-=" | "*=" | "/=" | "%=" | "**=" | "&lt;&lt;=" | "&gt;&gt;=" | "&gt;&gt;&gt;=" | "|=" | "^=" | "&=" | "||=" | "&&=" | "??="</code>


#### Pattern

<code><a href="#identifier">Identifier</a> | <a href="#objectpattern">ObjectPattern</a> | <a href="#arraypattern">ArrayPattern</a> | <a href="#restelement">RestElement</a> | <a href="#assignmentpattern">AssignmentPattern</a> | <a href="#memberexpression">MemberExpression</a></code>


#### BinaryOperator

<code>"==" | "!=" | "===" | "!==" | "&lt;" | "&lt;=" | "&gt;" | "&gt;=" | "&lt;&lt;" | "&gt;&gt;" | "&gt;&gt;&gt;" | "+" | "-" | "*" | "/" | "%" | "**" | "|" | "^" | "&" | "in" | "instanceof"</code>


#### CallExpression

<code><a href="#simplecallexpression">SimpleCallExpression</a> | <a href="#newexpression">NewExpression</a></code>


#### ChainElement

<code><a href="#simplecallexpression">SimpleCallExpression</a> | <a href="#memberexpression">MemberExpression</a></code>


#### Literal

<code><a href="#simpleliteral">SimpleLiteral</a> | <a href="#regexpliteral">RegExpLiteral</a> | <a href="#bigintliteral">BigIntLiteral</a></code>


#### LogicalOperator

<code>"||" | "&&" | "??"</code>


#### UnaryOperator

<code>"-" | "+" | "!" | "~" | "typeof" | "void" | "delete"</code>


#### UpdateOperator

<code>"++" | "--"</code>


#### Declaration

<code><a href="#functiondeclaration">FunctionDeclaration</a> | <a href="#variabledeclaration">VariableDeclaration</a> | <a href="#classdeclaration">ClassDeclaration</a></code>


#### SubscriptionEvent

<code>'PAYMENT_METHOD_INFO_CARD' | 'PAYMENT_METHOD_STATUS' | 'FORM_STATUS' | 'PAYMENT_METHOD_INFO_BILLING_ADDRESS'</code>


#### locale

<code>'en' | 'he' | 'fr' | 'en-GB' | 'ar' | 'ja' | 'de' | 'fr-BE' | 'es' | 'ca' | 'pt' | 'it' | 'pl' | 'nl' | 'nI-BE' | 'sv' | 'ru' | 'lt' | 'cs' | 'sk' | 'ls' | 'cy' | 'el' | 'et' | 'fi' | 'nb' | 'bs' | 'da' | 'ms' | 'tr-CY'</code>


#### RedirectionInfo

<code>'hidden' | 'shown'</code>


#### LayoutType

<code>'tabs' | 'accordion'</code>


#### PaymentMethodsArrangement

<code>'grid' | 'auto'</code>


#### CvcIconDisplay

<code>'shown' | 'hidden'</code>


#### CardBrandIconDisplay

<code>'hidden' | 'animated' | 'standard' | 'hideGeneric'</code>


#### GooglePayButtonType

<code>'BUY' | 'BOOK' | 'CHECKOUT' | 'DONATE' | 'ORDER' | 'PAY' | 'SUBSCRIBE' | 'PLAIN'</code>


#### GooglePayButtonStyle

<code>'light' | 'dark'</code>


#### ApplePayButtonType

<code>'buy' | 'setUp' | 'inStore' | 'donate' | 'checkout' | 'book' | 'subscribe' | 'plain'</code>


#### ApplePayButtonStyle

<code>'white' | 'whiteOutline' | 'black'</code>


#### PayPalButtonType

<code>'paypal' | 'checkout' | 'buynow' | 'pay'</code>


#### PayPalButtonStyle

<code>'gold' | 'blue' | 'white' | 'black' | 'silver'</code>

</docgen-api>
