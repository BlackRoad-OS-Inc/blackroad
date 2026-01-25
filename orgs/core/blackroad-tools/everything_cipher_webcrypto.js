#!/usr/bin/env node
/**
 * Minimal Node/WebCrypto implementation of the Everything Cipher (v1).
 *
 * Dependencies:
 *   npm install argon2
 *
 * Usage:
 *   node tools/everything_cipher_webcrypto.js enc < secret.txt > secret.ev1
 *   node tools/everything_cipher_webcrypto.js dec < secret.ev1 > plain.txt
 */
const { hkdfSync, randomBytes, webcrypto } = require('node:crypto');
const { stdin: input, stdout: output, argv, exit } = require('node:process');
const { Buffer } = require('node:buffer');
const { createInterface } = require('node:readline/promises');
const argon2 = require('argon2');

const ARGON2_MEMORY_MB = 64;
const ARGON2_TIME = 3;
const ARGON2_PARALLELISM = 1;
const AAD = new TextEncoder().encode('Peter Panda Dance v1');
const HKDF_INFO_CONTENT = new TextEncoder().encode('EV1/aes-gcm/content');
const HEADER_VERSION = 'EV1';
const KDF_NAME = 'argon2id';

function b64e(buf) {
  return Buffer.from(buf).toString('base64url');
}

function b64d(str) {
  return Buffer.from(str, 'base64url');
}

async function readStdin() {
  const chunks = [];
  for await (const chunk of input) {
    chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
  }
  return Buffer.concat(chunks);
}

async function promptPassphrase() {
  const rl = createInterface({ input: process.stdin, output: process.stderr, terminal: true });
  rl.stdoutMuted = true;
  rl._writeToOutput = function writeToOutput(stringToWrite) {
    if (rl.stdoutMuted) {
      if (stringToWrite.includes('\n')) {
        rl.output.write('\n');
      } else {
        rl.output.write('*');
      }
    } else {
      rl.output.write(stringToWrite);
    }
  };
  try {
    const answer = await rl.question('Passphrase: ');
    rl.output.write('\n');
    return answer;
  } finally {
    rl.stdoutMuted = false;
    rl.close();
  }
}

async function deriveRootKey(passphrase, salt) {
  return argon2.hash(passphrase, {
    type: argon2.argon2id,
    salt,
    raw: true,
    hashLength: 32,
    memoryCost: ARGON2_MEMORY_MB * 1024,
    timeCost: ARGON2_TIME,
    parallelism: ARGON2_PARALLELISM,
    version: 0x13,
  });
}

function hkdfSubkey(rootKey, hkdfSalt, info) {
  return hkdfSync('sha256', rootKey, hkdfSalt, info, 32);
}

async function encryptBlob(plaintext, passphrase) {
  const salt = randomBytes(16);
  const hkdfSalt = randomBytes(16);
  const nonce = randomBytes(12);

  const rootKey = await deriveRootKey(passphrase, salt);
  const encKey = hkdfSubkey(rootKey, hkdfSalt, HKDF_INFO_CONTENT);

  const cipher = await webcrypto.subtle.importKey('raw', encKey, 'AES-GCM', false, ['encrypt']);
  const ciphertext = new Uint8Array(
    await webcrypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce, additionalData: AAD }, cipher, plaintext)
  );

  const tokens = [
    HEADER_VERSION,
    `kdf=${KDF_NAME}`,
    `m=${ARGON2_MEMORY_MB}MB,t=${ARGON2_TIME},p=${ARGON2_PARALLELISM}`,
    `salt=${b64e(salt)}`,
    `hkdf_salt=${b64e(hkdfSalt)}`,
    `nonce=${b64e(nonce)}`,
    `ct=${b64e(ciphertext)}`,
  ];
  return tokens.join('|');
}

async function decryptBlob(blob, passphrase) {
  const tokens = blob.trim().split('|');
  if (tokens.length < 7 || tokens[0] !== HEADER_VERSION) {
    throw new Error('Unsupported or corrupted Everything Cipher header');
  }
  const params = {};
  for (const token of tokens.slice(1)) {
    if (token.startsWith('m=')) {
      params.argon2_params = token;
      continue;
    }
    const [key, value] = token.split('=');
    params[key] = value;
  }
  if (params.kdf !== KDF_NAME) {
    throw new Error('Unsupported KDF declared in header');
  }

  const salt = b64d(params.salt);
  const hkdfSalt = b64d(params.hkdf_salt);
  const nonce = b64d(params.nonce);
  const ciphertext = b64d(params.ct);

  const rootKey = await deriveRootKey(passphrase, salt);
  const encKey = hkdfSubkey(rootKey, hkdfSalt, HKDF_INFO_CONTENT);
  const key = await webcrypto.subtle.importKey('raw', encKey, 'AES-GCM', false, ['decrypt']);
  const plaintext = await webcrypto.subtle.decrypt(
    { name: 'AES-GCM', iv: nonce, additionalData: AAD },
    key,
    ciphertext
  );
  return new Uint8Array(plaintext);
}

async function main() {
  const [, , mode] = argv;
  if (!['enc', 'dec'].includes(mode)) {
    console.error('Usage: node tools/everything_cipher_webcrypto.js <enc|dec>');
    exit(1);
  }

  const stdinData = await readStdin();
  const passphrase = await promptPassphrase();

  if (mode === 'enc') {
    const blob = await encryptBlob(stdinData, passphrase);
    output.write(blob);
  } else {
    const plaintext = await decryptBlob(stdinData.toString('utf8'), passphrase);
    output.write(Buffer.from(plaintext));
  }
}

main().catch((err) => {
  console.error(err);
  exit(1);
});
