#!/usr/bin/env bash
set -euo pipefail

REPO="can1357/oh-my-pi"
HASHES_FILE="$(dirname "$0")/hashes.json"

command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }
command -v nix >/dev/null 2>&1 || { echo "nix is required"; exit 1; }

FORCE=false
for arg in "$@"; do
  if [ "$arg" = "--force" ]; then
    FORCE=true
  fi
done

# Order-deterministic list of (system assetName) pairs
SYSTEMS=(
  "x86_64-linux:omp-linux-x64"
  "aarch64-linux:omp-linux-arm64"
  "x86_64-darwin:omp-darwin-x64"
  "aarch64-darwin:omp-darwin-arm64"
)

echo "Fetching latest release from $REPO..."

RELEASE_JSON=$(curl -fsSL --connect-timeout 10 --max-time 30 \
  "https://api.github.com/repos/${REPO}/releases/latest")

TAG_NAME=$(echo "$RELEASE_JSON" | jq -r '.tag_name')
VERSION=${TAG_NAME#v}

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "Failed to fetch latest version"
  exit 1
fi

echo "Latest version: $VERSION (tag: $TAG_NAME)"

CURRENT_VERSION=$(jq -r '.version // "0"' "$HASHES_FILE")
if [ "$VERSION" = "$CURRENT_VERSION" ] && [ "$FORCE" = false ]; then
  echo "Version $VERSION is already current. Use --force to refresh hashes."
  exit 0
fi

if [ "$FORCE" = true ]; then
  echo "Force-refreshing hashes for version $VERSION..."
else
  echo "Updating from $CURRENT_VERSION to $VERSION..."
fi

SOURCES_JSON="{"
FIRST=true
for ENTRY in "${SYSTEMS[@]}"; do
  SYSTEM="${ENTRY%%:*}"
  ASSET_NAME="${ENTRY#*:}"
  URL="https://github.com/${REPO}/releases/download/${TAG_NAME}/${ASSET_NAME}"

  echo "  Hashing $SYSTEM ($ASSET_NAME)..."
  HASH=$(nix-prefetch-url --type sha256 "$URL" 2>/dev/null)

  if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
    echo "  ERROR: Failed to fetch hash for $SYSTEM"
    exit 1
  fi

  # Convert nix base32 hash to SRI format for consistency
  SRI=$(nix hash convert --hash-algo sha256 --to sri "sha256:$HASH" 2>/dev/null)

  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    SOURCES_JSON+=","
  fi

  SOURCES_JSON+="
    \"${SYSTEM}\": {
      \"url\": \"${URL}\",
      \"hash\": \"${SRI}\"
    }"
done
SOURCES_JSON+="
  }"

jq -n \
  --arg version "$VERSION" \
  --argjson sources "$(echo "$SOURCES_JSON")" \
  '{
    version: $version,
    sources: $sources
  }' > "$HASHES_FILE"

echo ""
echo "✓ Updated to version $VERSION"
echo ""
echo "Run 'nix build .#omp' to test the build."
