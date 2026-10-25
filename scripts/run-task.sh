#!/usr/bin/env bash
# Run work/job.sh <task>, then upload log, outputs, manifest and status to R2.
# The console gets one short status line. Everything else stays in job.log, which goes to R2.
set -uo pipefail
cd "$GITHUB_WORKSPACE"
. runner/scripts/r2.sh

mkdir -p "work/out/$TASK"
started=$SECONDS
# The job gets no R2 credentials: it cannot read or write the bucket itself.
( cd work && env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY -u R2_ACCOUNT_ID timeout 160m bash job.sh "$TASK" ) > job.log 2>&1
code=$?
secs=$((SECONDS - started))

upload_failed=0
s3 cp job.log "$PREFIX/logs/$TASK.log" || upload_failed=1
s3 cp "work/out/$TASK" "$PREFIX/out/$TASK/" --recursive --no-follow-symlinks || upload_failed=1

# MANIFEST.txt: one "<relative path><TAB><bytes>" line per output file. Written and uploaded last,
# and only when every upload worked, so its presence means the outputs are complete.
( cd "work/out/$TASK" && find . -type f ! -name MANIFEST.txt -printf '%P\t%s\n' | LC_ALL=C sort ) > MANIFEST.txt
files=$(wc -l < MANIFEST.txt | tr -d ' ')
bytes=$(awk -F'\t' '{ s += $2 } END { print s + 0 }' MANIFEST.txt)
if [ "$upload_failed" -eq 0 ]; then
  s3 cp MANIFEST.txt "$PREFIX/out/$TASK/MANIFEST.txt" || upload_failed=1
fi

printf '{"task":"%s","exit":%d,"seconds":%d}\n' "$TASK" "$code" "$secs" > status.json
s3 cp status.json "$PREFIX/status/$TASK.json" || upload_failed=1

if [ "$upload_failed" -eq 0 ]; then up=yes; else up=NO; fi
echo "task=$TASK exit=$code seconds=$secs files=$files bytes=$bytes uploaded=$up"
if [ "$upload_failed" -ne 0 ]; then echo "::error::upload to R2 failed"; exit 70; fi
if [ "$code" -ne 0 ]; then echo "::error::job.sh failed with exit $code (the log is in R2)"; exit "$code"; fi
