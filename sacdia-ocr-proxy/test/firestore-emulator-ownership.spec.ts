import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import type { ChildProcess } from 'node:child_process';
import { describe, it } from 'node:test';
import {
  type EmulatorControl,
  startFirestoreEmulator,
} from './support/firestore-emulator.ts';

describe('ownership del emulador local', () => {
  it('rechaza un puerto ocupado sin crear el proceso', async () => {
    let spawned = 0;
    await assert.rejects(
      () =>
        startFirestoreEmulator('/tmp/unused.jar', {
          listeningPid: async () => 4242,
          verifyJar: async () => {
            throw new Error('jar must not be read');
          },
          spawnJava: () => {
            spawned += 1;
            throw new Error('java must not start');
          },
        }),
      /already in use by pid 4242/,
    );
    assert.equal(spawned, 0);
  });

  it('no adopta un listener ajeno después de crear el proceso', async () => {
    const child = fakeJava(7);
    let probes = 0;
    await assert.rejects(
      () =>
        startFirestoreEmulator(
          '/tmp/unused.jar',
          control(child, async () => {
            probes += 1;
            return probes === 1 ? null : 99;
          }),
        ),
      /owned by pid 99, not emulator pid 7/,
    );
    assert.equal(child.exitCode, 0);
  });

  it('queda listo solo cuando el listener es el proceso propio', async () => {
    const child = fakeJava(11);
    let probes = 0;
    const started = await startFirestoreEmulator(
      '/tmp/unused.jar',
      control(child, async () => {
        probes += 1;
        return probes === 1 ? null : 11;
      }),
    );
    assert.equal(child.exitCode, null);
    await started.stop();
    assert.equal(child.exitCode, 0);
  });
});

function control(
  child: ChildProcess,
  listeningPid: EmulatorControl['listeningPid'],
): EmulatorControl {
  return {
    listeningPid,
    verifyJar: async () => undefined,
    spawnJava: (args) => {
      assert.equal(args[1], '--host');
      assert.equal(args[2], '127.0.0.1');
      assert.equal(args[3], '--port');
      assert.equal(args[4], '8099');
      return child;
    },
  };
}

function fakeJava(pid: number): ChildProcess {
  const child = new EventEmitter() as EventEmitter & {
    pid: number;
    exitCode: number | null;
    signalCode: NodeJS.Signals | null;
    stdout: null;
    stderr: null;
    kill: (signal?: NodeJS.Signals | number) => boolean;
  };
  child.pid = pid;
  child.exitCode = null;
  child.signalCode = null;
  child.stdout = null;
  child.stderr = null;
  child.kill = () => {
    if (child.exitCode == null) {
      child.exitCode = 0;
      child.emit('exit', 0, null);
    }
    return true;
  };
  return child as ChildProcess;
}
