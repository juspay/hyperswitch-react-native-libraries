// src/utils/masker/Masker.ts

export const PLACEHOLDERS = ['#', '@', 'a', 'A', '*'];

/**
 * Masks the input string based on the provided mask pattern.
 * @param input The raw input string.
 * @param pattern The mask pattern (e.g., "##/##").
 * @param divider Optional divider to submit within masked input.
 * @param prefix Optional prefix to prepend to the masked input.
 * @returns The masked input string.
 */
export const maskInput = (
  input: string,
  pattern: string,
  divider?: string, // optional; if provided, we replace non-placeholder chars
  prefix?: string
): string => {
  let formatted = prefix ?? '';
  let inputIndex = 0;
  const inputChars = input.split('');

  for (let i = 0; i < pattern.length; i++) {
    const patternChar = pattern[i];
    if (patternChar && PLACEHOLDERS.includes(patternChar)) {
      while (inputIndex < inputChars.length) {
        const currentInputChar = inputChars[inputIndex] ?? '';
        if (isValidCharacter(currentInputChar, patternChar)) {
          formatted += currentInputChar;
          inputIndex++;
          break;
        } else {
          inputIndex++;
        }
      }
      if (inputIndex >= inputChars.length) break;
    } else {
      // If divider is set, replace non-placeholder chars with it
      if (divider) {
        formatted += divider;
        // If the pattern char matches the current input char, skip it
        if (
          inputIndex < inputChars.length &&
          patternChar === inputChars[inputIndex]
        ) {
          inputIndex++;
        }
      } else {
        // Use the literal mask character
        formatted += patternChar;
        // Skip if it matches the current input char
        if (
          inputIndex < inputChars.length &&
          patternChar === inputChars[inputIndex]
        ) {
          inputIndex++;
        }
      }
    }
  }

  return formatted;
};

/**
 * Unmasks the input string by removing only the separators defined in the mask pattern.
 * @param maskedInput The masked input string.
 * @param pattern The mask pattern used to format the input.
 * @returns The raw input string without mask separators.
 */
export const unmaskInput = (maskedInput: string, pattern: string): string => {
  if (!pattern) return maskedInput; // If no pattern provided, return as-is

  // Identify separators by excluding placeholder characters
  const separators = pattern
    .split('')
    .filter((char) => !PLACEHOLDERS.includes(char))
    .join('');

  // Create a regex to remove only the identified separators
  const separatorsEscaped = separators.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&'); // Escape regex special chars
  const regex = new RegExp(`[${separatorsEscaped}]`, 'g');

  return maskedInput.replace(regex, '');
};

/**
 * Masks the input string based on the provided mask pattern.
 * @param maskedValue The masked input string.
 * @param pattern The mask pattern (e.g., "##/##").
 * @param divider Optional divider to submit within masked input.
 * @returns The value to submit.
 */
export const getUnmaskedValue = (
  maskedValue: string,
  pattern?: string,
  divider?: string
): string => {
  const rawValue = unmaskInput(maskedValue, pattern ?? '');

  if (divider && pattern) {
    // If a divider is provided, re-mask using the divider
    return maskInput(rawValue, pattern, divider);
  }
  // Otherwise, return the raw input
  return rawValue;
};

/**
 * Checks if a character is valid based on the pattern character.
 * @param char The character to validate.
 * @param patternChar The pattern character defining the type.
 * @returns True if valid, else false.
 */
export const isValidCharacter = (
  char: string,
  patternChar: string
): boolean => {
  switch (patternChar) {
    case '#':
      return /^[0-9]$/.test(char); // Digits only
    case '@':
      return /^[a-zA-Z]$/.test(char); // Any letter
    case 'a':
      return /^[a-z]$/.test(char); // Lowercase letters
    case 'A':
      return /^[A-Z]$/.test(char); // Uppercase letters
    case '*':
      return /^[a-zA-Z0-9]$/.test(char); // Any alphanumeric
    default:
      return false;
  }
};
