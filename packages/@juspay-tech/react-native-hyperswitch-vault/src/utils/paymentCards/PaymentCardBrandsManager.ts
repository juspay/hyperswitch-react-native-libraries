// PaymentCardBrandsManager.ts
import { Appearance } from 'react-native';
import { DEFAULT_BRANDS } from './PaymentCardBrand';
import type { PaymentCardBrand } from './PaymentCardBrand';

/**
 * Manages known card brands (both default and custom),
 * plus a special "unknown brand" fallback if user want to validate unknowns.
 */
export class PaymentCardBrandsManager {
  private static instance: PaymentCardBrandsManager;

  /** All known brands (default + custom). */
  private allBrands: PaymentCardBrand[] = [...DEFAULT_BRANDS];

  /**
   * Which brand names are currently allowed.
   * If a brand’s name is not in here, we skip it during `detectBrand`.
   */
  private allowedBrands: string[] = DEFAULT_BRANDS.map((brand) => brand.name);

  /** Optional fallback brand for unknown cards. */
  private unknownBrand?: PaymentCardBrand;

  private constructor() {}

  public defaultCardIcon = require('../../assets/cardIcons/Unknown-Light.png');

  public static getInstance(): PaymentCardBrandsManager {
    if (!PaymentCardBrandsManager.instance) {
      PaymentCardBrandsManager.instance = new PaymentCardBrandsManager();
    }
    return PaymentCardBrandsManager.instance;
  }

  /** Edit an existing brand by name. */
  public editBrand(
    brandName: string,
    updatedFields: Partial<PaymentCardBrand>
  ): void {
    this.allBrands = this.allBrands.map((brand) => {
      if (brand.name === brandName) {
        return { ...brand, ...updatedFields };
      }
      return brand;
    });
  }

  /** Add a custom brand to the list. */
  public addCustomBrand(customBrand: PaymentCardBrand): void {
    // Check if brand already exists before adding custom brand.
    if (!this.allBrands.some((b) => b.name === customBrand.name)) {
      this.allBrands.push(customBrand);
    }
  }

  /** Restrict which brand names are allowed. */
  public setAllowedBrands(brandNames: string[]): void {
    this.allowedBrands = brandNames;
  }

  /**
   * Detect the brand that matches this cardNumber. Returns undefined if
   * no brand's regex matches, or if brand is not allowed.
   */
  public detectBrand(cardNumber: string): PaymentCardBrand | undefined {
    return this.allBrands.find((brand) => {
      // Skip if brand not allowed
      if (!this.allowedBrands.includes(brand.name)) {
        return false;
      }
      // Regex test
      return brand.regex.test(cardNumber);
    });
  }

  /**
   * Sets the fallback brand for unknown cards
   */
  public setUnknownBrand(brand: PaymentCardBrand) {
    this.unknownBrand = brand;
  }

  /**
   * Gets the fallback brand for unknown cards, if any.
   */
  public getUnknownBrand(): PaymentCardBrand | undefined {
    return this.unknownBrand;
  }

  getBin(cardNumber: string, brandName: string): string | undefined {
    const specialBrands = ['Visa', 'VisaElectron', 'Mastercard', 'Maestro'];
    if (specialBrands.includes(brandName)) {
      return cardNumber.length >= 16 ? cardNumber.slice(0, 8) : undefined;
    } else {
      return cardNumber.length >= 6 ? cardNumber.slice(0, 6) : undefined;
    }
  }

  /**
   * Returns the brand object if its name matches the provided string;
   * otherwise, returns `undefined` or the unknownBrand if available.
   */
  getBrandByName(name: string): PaymentCardBrand | undefined {
    const brand = this.allBrands.find(
      (b) => b.name.toLowerCase() === name.toLowerCase()
    );
    if (!brand && this.unknownBrand) {
      return this.unknownBrand;
    }

    return brand;
  }

  getBrandIcon(name: string): any {
    const colorScheme = Appearance.getColorScheme(); // Detect light/dark mode
    const brand = this.allBrands.find(
      (b) => b.name.toLowerCase() === name.toLowerCase()
    );
    return brand?.icons[colorScheme || 'light'] || this.defaultCardIcon;
  }
}
