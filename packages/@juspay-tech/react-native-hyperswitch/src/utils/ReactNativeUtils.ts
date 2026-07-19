import { UIManager, findNodeHandle } from 'react-native';

export function dispatchViewManagerCommand(
  viewId: number,
  commandId: number,
  commandArgs: number[]
): void {
  UIManager.dispatchViewManagerCommand(viewId, commandId, commandArgs);
}

export function getFindNodeHandle(ref: unknown): number {
  return findNodeHandle(ref as React.ElementRef<typeof UIManager>) ?? -1;
}
