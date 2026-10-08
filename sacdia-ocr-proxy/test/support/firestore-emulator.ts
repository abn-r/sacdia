import { type ChildProcess, execFile, spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { createReadStream } from 'node:fs';

export const EMULATOR_SHA256 =
  '9b6498b7f62714d67f48f59b3818883cd682dbcd46b9f59511de81c97bb5166c';
export const EMULATOR_HOST = '127.0.0.1';
export const EMULATOR_PORT = 8099;
export const EMULATOR_PROJECT = 'demo-ocr-local';

const JAVA_ARGS = [
  '--host',
  EMULATOR_HOST,
  '--port',
  String(EMULATOR_PORT),
  '--project_id',
  EMULATOR_PROJECT,
  '--single_project_mode',
  'true',
  '--single_project_mode_error',
  'true',
  '--database-mode',
  'firestore-native',
  '--database-edition',
  'standard',
] as const;

export type EmulatorControl = {
  listeningPid: (port: number) => Promise<number | null>;
  spawnJava: (args: readonly string[]) => ChildProcess;
  verifyJar: (jarPath: string) => Promise<void>;
};

const defaultControl: EmulatorControl = {
  listeningPid,
  spawnJava(args) {
    return spawn('java', ['-jar', ...args], {
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  },
  verifyJar: assertEmulatorJar,
};

export async function assertEmulatorJar(jarPath: string): Promise<void> {
  const hash = createHash('sha256');
  await new Promise<void>((resolve, reject) => {
    const stream = createReadStream(jarPath);
    stream.on('data', (chunk) => hash.update(chunk));
    stream.on('error', reject);
    stream.on('end', () => resolve());
  });
  const actual = hash.digest('hex');
  if (actual !== EMULATOR_SHA256) {
    throw new Error(`emulator sha256 mismatch: ${actual}`);
  }
}

export async function startFirestoreEmulator(
  jarPath: string,
  control: EmulatorControl = defaultControl,
): Promise<{ stop: () => Promise<void> }> {
  const existing = await control.listeningPid(EMULATOR_PORT);
  if (existing != null) {
    throw new Error(`127.0.0.1:8099 is already in use by pid ${existing}`);
  }
  await control.verifyJar(jarPath);
  const child = control.spawnJava([jarPath, ...JAVA_ARGS]);
  const logs: Buffer[] = [];
  child.stdout?.on('data', (chunk: Buffer) => logs.push(chunk));
  child.stderr?.on('data', (chunk: Buffer) => logs.push(chunk));
  try {
    await waitForOwnListener(child, control);
  } catch (error) {
    child.kill('SIGKILL');
    const detail = Buffer.concat(logs).toString('utf8').slice(-2000);
    throw new Error(`${String(error)}\n${detail}`, { cause: error });
  }
  return { stop: () => stopChild(child) };
}

async function waitForOwnListener(
  child: ChildProcess,
  control: EmulatorControl,
): Promise<void> {
  const timeoutMs = 30_000;
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    if (child.exitCode != null || child.signalCode != null) {
      throw new Error(`emulator exited ${child.exitCode ?? child.signalCode}`);
    }
    if (child.pid == null) throw new Error('emulator process has no pid');
    const listener = await control.listeningPid(EMULATOR_PORT);
    if (listener == null) {
      await delay(200);
      continue;
    }
    if (listener !== child.pid) {
      throw new Error(
        `port 8099 is owned by pid ${listener}, not emulator pid ${child.pid}`,
      );
    }
    return;
  }
  throw new Error('emulator did not listen on 127.0.0.1:8099');
}

function listeningPid(port: number): Promise<number | null> {
  return new Promise((resolve, reject) => {
    execFile(
      'lsof',
      ['-nP', `-iTCP:${port}`, '-sTCP:LISTEN', '-t'],
      (error, stdout) => {
        if (error) {
          const failure = error as { code?: unknown; status?: unknown };
          if (failure.code === 'ENOENT') {
            reject(new Error('lsof is required to confirm emulator ownership'));
            return;
          }
          if (failure.code === 1 || failure.status === 1) {
            resolve(null);
            return;
          }
          reject(error);
          return;
        }
        const lines = stdout
          .split('\n')
          .map((line) => line.trim())
          .filter((line) => line.length > 0);
        if (lines.length === 0) {
          resolve(null);
          return;
        }
        if (lines.length !== 1) {
          reject(new Error(`port ${port} has more than one listener`));
          return;
        }
        const pid = Number(lines[0]);
        if (!Number.isInteger(pid) || pid <= 0) {
          reject(new Error(`unreadable listener pid for port ${port}`));
          return;
        }
        resolve(pid);
      },
    );
  });
}

function stopChild(child: ChildProcess): Promise<void> {
  return new Promise((resolve) => {
    if (child.exitCode != null) {
      resolve();
      return;
    }
    const timer = setTimeout(() => {
      if (child.exitCode == null) child.kill('SIGKILL');
    }, 4_000);
    child.once('exit', () => {
      clearTimeout(timer);
      resolve();
    });
    child.kill('SIGTERM');
  });
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
