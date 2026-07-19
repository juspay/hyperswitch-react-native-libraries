import type { CvcWidget } from '../definitions';

const registry = new Map<string, CvcWidget>();

export function registerWidget(id: string, widget: CvcWidget): void {
  registry.set(id, widget);
}

export function unregisterWidget(id: string): void {
  registry.delete(id);
}

export function getWidget(id: string): CvcWidget | undefined {
  return registry.get(id);
}
