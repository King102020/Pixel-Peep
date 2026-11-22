#!/usr/bin/env bash
# Vercel build: Vercel's images don't ship Flutter, so fetch the pinned SDK
# (cached between builds), then build the release web bundle into build/web.
set -euo pipefail

FLUTTER_VERSION="3.35.3"   # keep in sync with local `flutter --version`
SDK_DIR="${VERCEL_CACHE_DIR:-$HOME}/flutter-$FLUTTER_VERSION"

# Flutter's bootstrap needs these; Vercel's image (Amazon Linux 2023) may not.
missing=()
for tool in unzip find which xz tar curl; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "Installing build tools: ${missing[*]}"
  dnf install -y -q unzip findutils which xz tar curl-minimal
fi

if [ ! -x "$SDK_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK_DIR"
fi
export PATH="$SDK_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release
