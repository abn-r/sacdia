import { googleDeps } from './runtime/google-deps.ts';
import { startProduction } from './runtime/production.ts';

function write(line: string, done?: () => void): void {
  process.stderr.write(`${line}\n`, done);
}

try {
  await startProduction({
    env: process.env,
    deps: googleDeps,
    signals: process,
    exit: (code) => process.exit(code),
    log: (line) => write(line),
  });
} catch (error) {
  // Solo el mensaje de RuntimeConfigError (nombres de variables) o el código
  // del sistema; nunca el contenido de una excepción arbitraria.
  const name = error instanceof Error ? error.name : 'Error';
  const code = (error as NodeJS.ErrnoException | undefined)?.code;
  const message =
    name === 'RuntimeConfigError' && error instanceof Error
      ? error.message
      : `startup failed (${name}${typeof code === 'string' ? ` ${code}` : ''})`;
  write(JSON.stringify({ severity: 'ERROR', message }), () => process.exit(1));
}
