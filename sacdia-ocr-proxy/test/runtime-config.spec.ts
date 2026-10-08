import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import { describe, it } from 'node:test';
import {
  RuntimeConfigError,
  loadRuntimeConfig,
} from '../src/config/runtime-config.ts';

const CURRENT_SECRET = Buffer.from(
  'current-secret-0123456789abcdef!',
  'utf8',
).toString('base64');
const PREVIOUS_SECRET = Buffer.from(
  'previous-secret-0123456789abcdef',
  'utf8',
).toString('base64');

function baseEnv(): NodeJS.ProcessEnv {
  return {
    OCR_ENV: 'production',
    OCR_KID_CURRENT: 'k-2026-10',
    OCR_SECRET_CURRENT: CURRENT_SECRET,
    GOOGLE_CLOUD_PROJECT: 'sacdia-ocr-prod',
  };
}

function withEnv(extra: NodeJS.ProcessEnv): NodeJS.ProcessEnv {
  return { ...baseEnv(), ...extra };
}

function without(name: string): NodeJS.ProcessEnv {
  const env = baseEnv();
  delete env[name];
  return env;
}

function catchConfig(env: NodeJS.ProcessEnv): RuntimeConfigError {
  try {
    loadRuntimeConfig(env);
  } catch (error) {
    assert.ok(error instanceof RuntimeConfigError, String(error));
    return error;
  }
  throw new assert.AssertionError({ message: 'la configuración arrancó' });
}

function assertNoLeak(error: RuntimeConfigError, env: NodeJS.ProcessEnv) {
  const text = `${error.message}\n${JSON.stringify(error.issues)}\n${String(error.stack)}`;
  for (const secret of [CURRENT_SECRET, PREVIOUS_SECRET]) {
    assert.equal(text.includes(secret), false, 'el mensaje incluye un secreto');
  }
  for (const [name, value] of Object.entries(env)) {
    if (typeof value === 'string' && value.length >= 8) {
      assert.equal(text.includes(value), false, `el mensaje repite ${name}`);
    }
  }
}

describe('configuración de runtime de producción', () => {
  it('aplica los defaults y construye el llavero', () => {
    const config = loadRuntimeConfig(baseEnv());
    assert.equal(config.environment, 'production');
    assert.equal(config.ring.environment, 'production');
    assert.equal(config.ring.keys.length, 1);
    assert.equal(config.ring.keys[0]?.kid, 'k-2026-10');
    assert.deepEqual(
      Buffer.from(config.ring.keys[0]?.secret ?? []),
      Buffer.from(CURRENT_SECRET, 'base64'),
    );
    assert.equal(config.port, 8080);
    assert.equal(config.pageLimit, 400);
    assert.equal(config.shutdownGraceMs, 8_000);
    assert.equal(config.projectId, 'sacdia-ocr-prod');
  });

  it('acepta la configuración completa con clave previa', () => {
    const config = loadRuntimeConfig(
      withEnv({
        OCR_KID_PREVIOUS: 'k-2026-09',
        OCR_SECRET_PREVIOUS: PREVIOUS_SECRET,
        OCR_MAX_PAGES_PER_ENV_PER_DAY: '25',
        PORT: '9090',
        OCR_SHUTDOWN_GRACE_MS: '5000',
      }),
    );
    assert.deepEqual(
      config.ring.keys.map((key) => key.kid),
      ['k-2026-10', 'k-2026-09'],
    );
    assert.deepEqual(
      Buffer.from(config.ring.keys[1]?.secret ?? []),
      Buffer.from(PREVIOUS_SECRET, 'base64'),
    );
    assert.equal(config.pageLimit, 25);
    assert.equal(config.port, 9090);
    assert.equal(config.shutdownGraceMs, 5000);
  });

  it('acepta los topes exactos de cada variable numérica', () => {
    const config = loadRuntimeConfig(
      withEnv({
        OCR_MAX_PAGES_PER_ENV_PER_DAY: '1',
        PORT: '65535',
        OCR_SHUTDOWN_GRACE_MS: '9000',
      }),
    );
    assert.equal(config.pageLimit, 1);
    assert.equal(config.port, 65_535);
    assert.equal(config.shutdownGraceMs, 9_000);
    assert.equal(
      loadRuntimeConfig(withEnv({ OCR_MAX_PAGES_PER_ENV_PER_DAY: '400' }))
        .pageLimit,
      400,
    );
    assert.equal(
      loadRuntimeConfig(withEnv({ OCR_SHUTDOWN_GRACE_MS: '100' }))
        .shutdownGraceMs,
      100,
    );
  });

  const invalid: Array<[string, string, NodeJS.ProcessEnv]> = [
    ['OCR_ENV', 'falta', without('OCR_ENV')],
    ['OCR_ENV', 'vacío', withEnv({ OCR_ENV: '' })],
    ['OCR_ENV', 'mayúsculas', withEnv({ OCR_ENV: 'Production' })],
    ['OCR_ENV', 'guion bajo', withEnv({ OCR_ENV: 'prod_env' })],
    ['OCR_ENV', 'termina en guion', withEnv({ OCR_ENV: 'prod-' })],
    ['OCR_ENV', 'demasiado largo', withEnv({ OCR_ENV: 'a'.repeat(33) })],
    ['OCR_KID_CURRENT', 'falta', without('OCR_KID_CURRENT')],
    ['OCR_KID_CURRENT', 'vacío', withEnv({ OCR_KID_CURRENT: '' })],
    [
      'OCR_KID_CURRENT',
      'empieza con guion',
      withEnv({ OCR_KID_CURRENT: '-k' }),
    ],
    [
      'OCR_KID_CURRENT',
      'con salto de línea',
      withEnv({ OCR_KID_CURRENT: 'k\nx' }),
    ],
    ['OCR_SECRET_CURRENT', 'falta', without('OCR_SECRET_CURRENT')],
    ['OCR_SECRET_CURRENT', 'vacío', withEnv({ OCR_SECRET_CURRENT: '' })],
    [
      'OCR_SECRET_CURRENT',
      'no es base64',
      withEnv({
        OCR_SECRET_CURRENT: 'esto-no-es-base64-valido!!-nada-que-ver',
      }),
    ],
    [
      'OCR_SECRET_CURRENT',
      'base64 sin relleno (no canónico)',
      withEnv({ OCR_SECRET_CURRENT: CURRENT_SECRET.replace(/=+$/, '') }),
    ],
    [
      'OCR_SECRET_CURRENT',
      'base64url',
      withEnv({
        OCR_SECRET_CURRENT: Buffer.from(
          '\xfb\xff\xfe-0123456789abcdef0123456789abcdefgh',
          'latin1',
        ).toString('base64url'),
      }),
    ],
    [
      'OCR_SECRET_CURRENT',
      'menos de 32 bytes',
      withEnv({
        OCR_SECRET_CURRENT: Buffer.alloc(31, 7).toString('base64'),
      }),
    ],
    [
      'OCR_SECRET_CURRENT',
      'bits sobrantes no cero (ida y vuelta)',
      withEnv({
        OCR_SECRET_CURRENT:
          Buffer.alloc(33, 7).toString('base64').slice(0, -2) + 'B=',
      }),
    ],
    [
      'OCR_SECRET_PREVIOUS',
      'kid previo sin secreto',
      withEnv({ OCR_KID_PREVIOUS: 'k-old' }),
    ],
    [
      'OCR_KID_PREVIOUS',
      'secreto previo sin kid',
      withEnv({ OCR_SECRET_PREVIOUS: PREVIOUS_SECRET }),
    ],
    [
      'OCR_KID_PREVIOUS',
      'kid inválido',
      withEnv({
        OCR_KID_PREVIOUS: 'k old',
        OCR_SECRET_PREVIOUS: PREVIOUS_SECRET,
      }),
    ],
    [
      'OCR_SECRET_PREVIOUS',
      'secreto corto',
      withEnv({
        OCR_KID_PREVIOUS: 'k-old',
        OCR_SECRET_PREVIOUS: Buffer.alloc(16, 1).toString('base64'),
      }),
    ],
    [
      'OCR_KID_PREVIOUS',
      'mismo kid que el actual',
      withEnv({
        OCR_KID_PREVIOUS: 'k-2026-10',
        OCR_SECRET_PREVIOUS: PREVIOUS_SECRET,
      }),
    ],
    [
      'OCR_KID_PREVIOUS',
      'vacío con secreto previo',
      withEnv({
        OCR_KID_PREVIOUS: '',
        OCR_SECRET_PREVIOUS: PREVIOUS_SECRET,
      }),
    ],
    ...['0', '401', '4.5', '1e2', 'abc', '', '-1', '010', ' 5'].map(
      (value): [string, string, NodeJS.ProcessEnv] => [
        'OCR_MAX_PAGES_PER_ENV_PER_DAY',
        `valor ${JSON.stringify(value)}`,
        withEnv({ OCR_MAX_PAGES_PER_ENV_PER_DAY: value }),
      ],
    ),
    ...['0', '65536', 'abc', '80.5', '', '-1', '08080', '8080 '].map(
      (value): [string, string, NodeJS.ProcessEnv] => [
        'PORT',
        `valor ${JSON.stringify(value)}`,
        withEnv({ PORT: value }),
      ],
    ),
    ...['0', '99', '9001', 'abc', '', '1.5', '-5'].map(
      (value): [string, string, NodeJS.ProcessEnv] => [
        'OCR_SHUTDOWN_GRACE_MS',
        `valor ${JSON.stringify(value)}`,
        withEnv({ OCR_SHUTDOWN_GRACE_MS: value }),
      ],
    ),
    ['GOOGLE_CLOUD_PROJECT', 'falta', without('GOOGLE_CLOUD_PROJECT')],
    ['GOOGLE_CLOUD_PROJECT', 'vacío', withEnv({ GOOGLE_CLOUD_PROJECT: '' })],
    [
      'GOOGLE_CLOUD_PROJECT',
      'forma inválida',
      withEnv({ GOOGLE_CLOUD_PROJECT: 'Bad_Project' }),
    ],
    [
      'GOOGLE_CLOUD_PROJECT',
      'proyecto demo-',
      withEnv({ GOOGLE_CLOUD_PROJECT: 'demo-ocr-local' }),
    ],
    [
      'FIRESTORE_EMULATOR_HOST',
      'emulador definido',
      withEnv({ FIRESTORE_EMULATOR_HOST: '127.0.0.1:8099' }),
    ],
    [
      'FIRESTORE_EMULATOR_HOST',
      'emulador definido pero vacío',
      withEnv({ FIRESTORE_EMULATOR_HOST: '' }),
    ],
    [
      'GOOGLE_APPLICATION_CREDENTIALS',
      'credencial explícita',
      withEnv({ GOOGLE_APPLICATION_CREDENTIALS: '/secrets/sa-key.json' }),
    ],
  ];

  for (const [name, label, env] of invalid) {
    it(`falla cerrado: ${name} (${label}) y no filtra valores`, () => {
      const error = catchConfig(env);
      assert.ok(
        error.issues.some((issue) => issue.name === name),
        `faltó ${name} en ${JSON.stringify(error.issues)}`,
      );
      assert.ok(error.message.includes(name));
      assertNoLeak(error, env);
    });
  }

  it('informa todas las variables inválidas a la vez, solo por nombre', () => {
    const env: NodeJS.ProcessEnv = {
      OCR_ENV: 'MAL',
      OCR_KID_CURRENT: '',
      OCR_SECRET_CURRENT: 'secreto-crudo-que-no-debe-salir-nunca',
      GOOGLE_CLOUD_PROJECT: 'demo-x1',
      FIRESTORE_EMULATOR_HOST: '127.0.0.1:8099',
      PORT: 'nope',
    };
    const error = catchConfig(env);
    const names = error.issues.map((issue) => issue.name);
    for (const expected of [
      'OCR_ENV',
      'OCR_KID_CURRENT',
      'OCR_SECRET_CURRENT',
      'GOOGLE_CLOUD_PROJECT',
      'FIRESTORE_EMULATOR_HOST',
      'PORT',
    ]) {
      assert.ok(names.includes(expected), `faltó ${expected}`);
    }
    assertNoLeak(error, env);
    assert.equal(error.message.includes('secreto-crudo'), false);
  });

  it('ignora variables ajenas', () => {
    const config = loadRuntimeConfig(
      withEnv({ NODE_ENV: 'production', K_SERVICE: 'ocr', HOME: '/root' }),
    );
    assert.equal(config.port, 8080);
  });
});
