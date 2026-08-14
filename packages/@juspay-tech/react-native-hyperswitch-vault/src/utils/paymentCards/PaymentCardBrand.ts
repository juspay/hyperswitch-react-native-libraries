// PaymentCardBrand.ts

export enum CheckSumAlgorithmType {
  LUHN = 'luhn',
  NONE = 'none',
}

export interface PaymentCardBrand {
  name: string; // e.g. "visa", "mastercard", etc.
  mask: string; // Used to format card input.
  regex: RegExp; // Used to detect the brand.
  cardNumberLengths: number[]; // Valid lengths for card number.
  cvcLengths: number[]; // Valid lengths for CVC.
  checkSumAlgorithm: CheckSumAlgorithmType;
  icons?: any; // Optional icon for the brand.
}

export const DEFAULT_CARD_MASK_16 = '#### #### #### ####';
export const DEFAULT_CARD_MASK_19 = '#### #### #### #### ###';

// Example defaults
export const DEFAULT_BRANDS: PaymentCardBrand[] = [
  {
    name: 'elo',
    mask: DEFAULT_CARD_MASK_16,
    regex:
      /^(4011(78|79)|43(1274|8935)|45(1416|7393|763(1|2))|50(4175|6699|67[0-7][0-9]|9000)|627780|63(6297|6368)|650(03([^4])|04([0-9])|05(0|1)|4(0[5-9]|3[0-9]|8[5-9]|9[0-9])|5([0-2][0-9]|3[0-8])|9([2-6][0-9]|7[0-8])|541|700|720|901)|651652|655000|655021)/,
    cardNumberLengths: [16],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/ELO-Light.png'),
      dark: require('../../assets/cardIcons/ELO-Dark.png'),
    },
  },
  {
    name: 'visaelectron',
    mask: DEFAULT_CARD_MASK_16,
    regex: /^4(026|17500|405|508|844|91[37])/,
    cardNumberLengths: [16],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/VisaElectron-Light.png'),
      dark: require('../../assets/cardIcons/VisaElectron-Dark.png'),
    },
  },
  {
    name: 'maestro',
    mask: DEFAULT_CARD_MASK_19,
    regex: /^(5018|5020|5038|6304|6390[0-9]{2}|67[0-9]{4}|5[6-9])/,
    cardNumberLengths: [12, 13, 14, 15, 16, 17, 18, 19],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/Maestro-Light.png'),
      dark: require('../../assets/cardIcons/Maestro-Dark.png'),
    },
  },
  {
    name: 'forbrugsforeningen',
    mask: DEFAULT_CARD_MASK_16,
    regex: /^600/,
    cardNumberLengths: [16],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/Forbrugsforeningen-Light.png'),
      dark: require('../../assets/cardIcons/Forbrugsforeningen-Dark.png'),
    },
  },
  {
    name: 'dankort',
    mask: DEFAULT_CARD_MASK_16,
    regex: /^5019/,
    cardNumberLengths: [16],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/Dankort-Light.png'),
      dark: require('../../assets/cardIcons/Dankort-Dark.png'),
    },
  },
  {
    name: 'visa',
    mask: DEFAULT_CARD_MASK_19,
    regex: /^4/,
    cardNumberLengths: [13, 16, 19],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/Visa-Light.png'),
      dark: require('../../assets/cardIcons/Visa-Dark.png'),
    },
  },
  {
    name: 'mastercard',
    mask: DEFAULT_CARD_MASK_16,
    regex:
      /^(5[1-5][0-9]{4})|^(222[1-9]|22[3-9]|2[3-6]\d{2}|27[0-1]\d|2720)([0-9]{2})/,
    cardNumberLengths: [16],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/Mastercard-Light.png'),
      dark: require('../../assets/cardIcons/Mastercard-Dark.png'),
    },
  },
  {
    name: 'amex',
    mask: '#### ###### #####',
    regex: /^3[47]/,
    cardNumberLengths: [15],
    cvcLengths: [4],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/Amex-Light.png'),
      dark: require('../../assets/cardIcons/Amex-Dark.png'),
    },
  },
  {
    name: 'hipercard',
    mask: DEFAULT_CARD_MASK_19,
    regex: /^(384100|384140|384160|606282|637095|637568|60(?!11))/,
    cardNumberLengths: [14, 15, 16, 17, 18, 19],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/Hipercard-Light.png'),
      dark: require('../../assets/cardIcons/Hipercard-Dark.png'),
    },
  },
  {
    name: 'dinersclub',
    mask: '#### ###### #########',
    regex: /^3(?:[689]|(?:0[059]+))/,
    cardNumberLengths: [14, 16, 17, 18, 19],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/Diners-Light.png'),
      dark: require('../../assets/cardIcons/Diners-Dark.png'),
    },
  },
  {
    name: 'discover',
    mask: DEFAULT_CARD_MASK_19,
    regex: /^(6011|65|64[4-9]|622)/,
    cardNumberLengths: [16, 17, 18, 19],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/Discover-Light.png'),
      dark: require('../../assets/cardIcons/Discover-Dark.png'),
    },
  },
  {
    name: 'unionpay',
    mask: DEFAULT_CARD_MASK_19,
    regex: /^62/,
    cardNumberLengths: [16, 17, 18, 19],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.NONE, // No Luhn check
    icons: {
      light: require('../../assets/cardIcons/UnionPay-Light.png'),
      dark: require('../../assets/cardIcons/UnionPay-Dark.png'),
    },
  },
  {
    name: 'jcb',
    mask: DEFAULT_CARD_MASK_19,
    regex: /^(2131|1800|35)/,
    cardNumberLengths: [16, 17, 18, 19],
    cvcLengths: [3],
    checkSumAlgorithm: CheckSumAlgorithmType.LUHN,
    icons: {
      light: require('../../assets/cardIcons/JCB-Light.png'),
      dark: require('../../assets/cardIcons/JCB-Dark.png'),
    },
  },
];
