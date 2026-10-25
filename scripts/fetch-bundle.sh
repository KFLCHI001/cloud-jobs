#!/usr/bin/env bash
# Download jobs/<job>/bundle.tar.gz (or the split parts) from R2 and extract it to work/.
set -euo pipefail
cd "$GITHUB_WORKSPACE"
if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ] || [ -z "${R2_ACCOUNT_ID:-}" ]; then
  echo "::error::R2 secrets are not set on this repo"; exit 1
fi
. runner/scripts/r2.sh
fail() { echo "::error::$1"; exit 1; }

if s3 cp "$PREFIX/bundle.parts" bundle.parts; then
  n="$(tr -dc '0-9' < bundle.parts)"
  [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le 200 ] || fail "bundle.parts is not a valid count"
  : > bundle.tar.gz
  for ((i = 0; i < n; i++)); do
    s3 cp "$PREFIX/bundle.tar.gz.$(printf '%03d' "$i")" - >> bundle.tar.gz || fail "could not download bundle part $i"
  done
else
  s3 cp "$PREFIX/bundle.tar.gz" bundle.tar.gz || fail "could not download the bundle"
fi

mkdir work
tar -xzf bundle.tar.gz -C work 2>/dev/null || fail "could not extract the bundle"
rm -f bundle.tar.gz bundle.parts
[ -f work/job.sh ] || fail "the bundle has no job.sh at its top level"
echo "bundle ready"
