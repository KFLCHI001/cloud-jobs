#!/usr/bin/env bash
# Sample job.sh for the hyperframes profile. It runs in the bundle root and $1 is the task name.
# Task "intro" renders intro.html to out/intro/intro.mp4 at draft quality.
# Keep the HyperFrames version in step with scripts/setup-profile.sh.
set -euo pipefail
mkdir -p "out/$1"
npx --yes hyperframes@0.8.192 render -c "$1.html" -q draft -o "out/$1/$1.mp4" --quiet
