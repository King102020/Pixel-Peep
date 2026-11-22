#!/usr/bin/env bash
# Vercel build: Vercel's images don't ship Flutter, so fetch the pinned SDK
# (cached between builds), then build the release web bundle into build/web.
set -euo pipefail

FLUTTER_VERSION="3.35.3"   # keep in sync with local `flutter --version`
SDK_DIR="${VERCEL_CACHE_DIR:-$HOME}/flutter-$FLUTTER_VERSION"

# Flutter's bootstrap unzips the Dart SDK; Vercel's image may not have unzip.
if ! command -v unzip >/dev/null 2>&1; then
  dnf install -y unzip >/dev/null 2>&1 || yum install -y unzip >/dev/null 2>&1 || true
fi

if [ ! -x "$SDK_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK_DIR"
fi
export PATH="$SDK_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release
