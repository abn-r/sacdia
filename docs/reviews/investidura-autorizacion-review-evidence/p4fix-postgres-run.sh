set -eu
pgbin=/opt/homebrew/opt/postgresql@18/bin
scratch=$(mktemp -d /tmp/sacdia-p4fix-independent.XXXXXX)
printf '%s\n' "$scratch" > /tmp/sacdia-p4fix-independent-path
port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
cleanup() { "$pgbin/pg_ctl" -D "$scratch/data" -m fast -w stop > "$scratch/stop.log" 2>&1 || true; }
trap cleanup EXIT INT TERM
"$pgbin/initdb" -D "$scratch/data" -U codex_p4fix_review -A trust --no-locale -E UTF8 > "$scratch/initdb.log" 2>&1
mkdir "$scratch/socket"
"$pgbin/pg_ctl" -D "$scratch/data" -l "$scratch/postgres.log" -o "-h 127.0.0.1 -p $port -k $scratch/socket" -w start > "$scratch/start.log" 2>&1
"$pgbin/createdb" -h127.0.0.1 -p "$port" -U codex_p4fix_review sacdia_p4fix_review_test
"$pgbin/psql" -X -h127.0.0.1 -p "$port" -U codex_p4fix_review -d sacdia_p4fix_review_test -vON_ERROR_STOP=1 -Atc "SELECT current_database(), inet_server_addr(), current_setting('data_directory'), current_setting('transaction_isolation');" > "$scratch/identity.log"
export SACDIA_TEST_DATABASE_URL="postgresql://codex_p4fix_review@127.0.0.1:$port/sacdia_p4fix_review_test"
export DATABASE_URL="$SACDIA_TEST_DATABASE_URL" DATABASE_DIRECT_URL="$SACDIA_TEST_DATABASE_URL" DOTENV_CONFIG_PATH=/dev/null NODE_ENV=test EMAIL_ENABLED=false REDIS_URL=''
set +e
./node_modules/.bin/jest --config test/jest-e2e.json --runInBand --no-coverage --runTestsByPath test/investiture-authorization-requests-postgres.e2e-spec.ts > "$scratch/postgres-tests.log" 2>&1
result=$?
set -e
printf '%s\n' "$result" > "$scratch/exit-code"
cat "$scratch/identity.log"; tail -18 "$scratch/postgres-tests.log"
if [ "$result" != 0 ]; then exit "$result"; fi
export TS_NODE_SKIP_PROJECT=true
export TS_NODE_COMPILER_OPTIONS='{"module":"CommonJS","moduleResolution":"Node","ignoreDeprecations":"6.0","experimentalDecorators":true,"emitDecoratorMetadata":true,"esModuleInterop":true,"target":"ES2022"}'
node -r ./node_modules/ts-node/register/transpile-only ../docs/reviews/investidura-autorizacion-review-evidence/p4fix-request-reuse-probe.cjs > "$scratch/probe.log" 2>&1
cat "$scratch/probe.log"
