#!/bin/sh
# BCR33 review (2026-10-07). Throwaway PG only (127.0.0.1:55525, *_test DB). Needs one local_fields row.
# Question (BCR33-N2): instance A claims the day (INSERT ... ON CONFLICT DO NOTHING RETURNING), its
# render fails and it releases the claim (DELETE) in the same tx. Instance B runs the same INSERT
# concurrently. Does B wait and then claim exactly once (no double claim, no lost day)?
# Control: A keeps its claim (no DELETE) -> B must get 0 rows.
P="psql -X -q -h 127.0.0.1 -p 55525 -U postgres -d sacdia_bcr33rev_test"
F=$($P -t -A -c "SELECT min(local_field_id) FROM local_fields")
cleanup() { $P -c "DELETE FROM investiture_reminder_runs WHERE local_field_id = $F AND role = 'pastor' AND local_date IN ('2026-10-05','2026-10-06')"; }
cleanup
for mode in release keep; do
  D=2026-10-05
  [ "$mode" = keep ] && D=2026-10-06
  INS="INSERT INTO investiture_reminder_runs (local_field_id, role, local_date) VALUES ($F, 'pastor', '$D') ON CONFLICT (local_field_id, role, local_date) DO NOTHING RETURNING local_field_id"
  DEL=""
  [ "$mode" = release ] && DEL="DELETE FROM investiture_reminder_runs WHERE local_field_id = $F AND role = 'pastor' AND local_date = '$D';"
  OUT=/tmp/bcr33rev-A.$mode
  ( $P -t -A -c "BEGIN; $INS; SELECT pg_sleep(2); $DEL COMMIT;" > $OUT 2>&1 ) &
  sleep 0.5
  START=$(date +%s)
  B=$($P -t -A -c "$INS" 2>&1)
  END=$(date +%s)
  wait
  ROWS=$($P -t -A -c "SELECT count(*) FROM investiture_reminder_runs WHERE local_field_id = $F AND role = 'pastor' AND local_date = '$D'")
  echo "mode=$mode A_claimed=[$(tr '\n' ' ' < $OUT)] B_claimed=[$B] B_waited_s=$((END-START)) rows_after=$ROWS"
  rm -f $OUT
done
cleanup
