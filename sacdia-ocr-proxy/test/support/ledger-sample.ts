export const DIGEST =
  '97f9d8301938ef5542f5ac8023d73f35749811eddc5a06844dd82433fe7b6de0';
export const OTHER_DIGEST =
  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
export const NOW = new Date('2026-10-02T15:04:05.006Z');
export const ISSUED_AT = NOW.toISOString();
export const NONCE = '0123456789abcdef0123456789abcdef';

export function operationId(index: number): string {
  return `11111111-1111-4111-8111-${index.toString(16).padStart(12, '0')}`;
}

export function nonceFor(index: number): string {
  return index.toString(16).padStart(32, '0');
}
