/**
 * Allows using types that codegen doesn't support, which will be generated
 * as mixed, but keeping the TS type for type-checking.
 *
 * Note that for some reason this only works for native components, not for turbo modules.
 */
export type UnsafeMixed<T> = T;
