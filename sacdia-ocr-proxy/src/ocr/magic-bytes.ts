const PDF = [0x25, 0x50, 0x44, 0x46, 0x2d];
const JPEG = [0xff, 0xd8, 0xff];
const PNG = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
const RIFF = [0x52, 0x49, 0x46, 0x46];
const WEBP = [0x57, 0x45, 0x42, 0x50];

export function magicMatchesMime(mime: string, body: Uint8Array): boolean {
  if (mime === 'application/pdf') return hasPrefix(body, PDF);
  if (mime === 'image/jpeg') return hasPrefix(body, JPEG);
  if (mime === 'image/png') return hasPrefix(body, PNG);
  if (mime === 'image/webp') {
    return hasPrefix(body, RIFF) && hasPrefix(body.subarray(8), WEBP);
  }
  return false;
}

function hasPrefix(body: Uint8Array, prefix: readonly number[]): boolean {
  if (body.byteLength < prefix.length) return false;
  for (let index = 0; index < prefix.length; index += 1) {
    if (body[index] !== prefix[index]) return false;
  }
  return true;
}
