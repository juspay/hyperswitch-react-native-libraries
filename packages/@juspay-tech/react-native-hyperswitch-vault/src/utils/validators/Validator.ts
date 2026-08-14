// Validator.ts

export const validateInput = (
  input: string,
  rules: ValidationRule[]
): string[] => {
  return rules
    .filter((rule) => !rule.validate(input))
    .map((rule) => rule.errorMessage);
};

abstract class ValidationRule {
  public readonly errorMessage: string;

  constructor(errorMessage: string) {
    this.errorMessage = errorMessage;
  }
  abstract validate(input: string): boolean;
}

export { ValidationRule };
