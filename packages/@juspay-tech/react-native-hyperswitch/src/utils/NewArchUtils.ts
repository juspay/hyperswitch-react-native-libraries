declare global {
  var __turboModuleProxy: unknown | undefined;
  var nativeFabricUIManager: unknown | undefined;
}

export function isTurboModuleEnabled(): boolean {
  return (
    typeof global.__turboModuleProxy !== 'undefined' &&
    global.__turboModuleProxy !== null
  );
}

export function isFabricEnabled(): boolean {
  return (
    typeof global.nativeFabricUIManager !== 'undefined' &&
    global.nativeFabricUIManager !== null
  );
}
