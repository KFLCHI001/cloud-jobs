#!/usr/bin/env bash
# Install what the profile needs. Everything here is generic and its output is safe to be public.
set -euo pipefail
apt_install() { sudo apt-get install -y -qq --no-install-recommends "$@" >/dev/null; }
sudo apt-get update -qq >/dev/null

case "$PROFILE" in
  hyperframes)
    apt_install ffmpeg fonts-liberation fonts-noto-core fonts-noto-color-emoji
    # Chrome's shared libraries. Names differ between Ubuntu releases, so try each one on its own.
    for p in libnss3 libatk-bridge2.0-0t64 libatk1.0-0t64 libgbm1 libasound2t64 libxkbcommon0 libxdamage1 \
             libxrandr2 libcups2t64 libpango-1.0-0 libcairo2 libxcomposite1 libxfixes3 libnspr4 libdrm2 \
             libatspi2.0-0t64 libxshmfence1 libx11-xcb1; do
      apt_install "$p" || echo "skipped package $p"
    done
    # The version is pinned here. examples/hyperframes/job.sh must use the same one.
    (cd "$RUNNER_TEMP" && npx --yes hyperframes@0.8.192 browser ensure)
    ;;
  ffmpeg)
    apt_install ffmpeg fonts-liberation fonts-noto-core
    ;;
  python)
    apt_install python3 python3-pip python3-venv ffmpeg
    ;;
  node)
    ;;
  *)
    echo "::error::unknown profile"; exit 1 ;;
esac
echo "profile $PROFILE ready"
