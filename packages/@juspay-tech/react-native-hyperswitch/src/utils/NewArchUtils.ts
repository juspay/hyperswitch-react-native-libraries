declare global {
  var __turboModuleProxy: unknown | null | undefined;
  var nativeFabricUIManager: unknown | null | undefined;
}

export function isTurboModuleEnabled(): boolean {
  return (
    typeof global.__turboModuleProxy !== 'undefined' &&
    global.__turboModuleProxy !== null
  );
}

export function isFabricEnabled(): boolean {
  const enabled = global.nativeFabricUIManager != null;
  console.log('isFabricEnabled', enabled);
  return enabled;
}
