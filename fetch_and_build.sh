#!/usr/bin/env bash
set -euo pipefail

tempdir="$(mktemp -d)"
cd "$tempdir"

gh release download "v${ATUIN_TAG}" --repo atuinsh/atuin --pattern "source.tar.gz" --pattern "source.tar.gz.sha256"

sha256 -c source.tar.gz < source.tar.gz.sha256

tar -xf source.tar.gz

cd "atuin-${ATUIN_TAG}"

cargo build --locked --release

echo "ATUIN_RELEASE_BIN_PATH=${tempdir}/atuin-${ATUIN_TAG}/target/release/atuin.exe" >> "${GITHUB_ENV}"
