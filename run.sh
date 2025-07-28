#!/usr/bin/env bash
set -euo pipefail

msg() { echo >&2 -e "${1-}"; }

die() {
  local msg=$1
  local code=${2-1}
  msg "$msg"
  exit "$code"
}

cmd__prep() {
  msg "Checking requirements"
  command -v gh >/dev/null 2>&1 || die "gh missing"
  command -v cargo >/dev/null 2>&1 || die "cargo missing"
  command -v sha256sum >/dev/null 2>&1 || die "sha256sum missing"

  msg "Creating temp dir"
  tempdir="$(mktemp -d)"
  cd "$tempdir"

  msg "Writing workdir path to ATUIN_WORKDIR"
  echo "ATUIN_WORKDIR=${tempdir}" >> "${GITHUB_ENV}"

  msg "Done"
}
cmd__fetch() {
  cd "${ATUIN_WORKDIR}"

  msg "Fetching artifacts for Atuin ${ATUIN_TAG} into re"
  gh release download "v${ATUIN_TAG}" --repo atuinsh/atuin --pattern "source.tar.gz" --pattern "source.tar.gz.sha256"

  msg "Verifying checksum"
  sha256sum -c source.tar.gz.sha256

  msg "Writing sources path to ATUIN_SOURCES_PATH"
  echo "ATUIN_SOURCES_PATH=${ATUIN_WORKDIR}/source.tar.gz" >> "${GITHUB_ENV}"

  msg "Done"
}

cmd__build() {
  cd "${ATUIN_WORKDIR}"

  msg "Extracting"
  tar -xf "source.tar.gz"

  cd "atuin-${ATUIN_TAG}"

  msg "Building"
  cargo build --locked --release

  msg "Writing target binary path to ATUIN_TARGET_BIN_PATH"
  echo "ATUIN_TARGET_BIN_PATH=${ATUIN_WORKDIR}/atuin-${ATUIN_TAG}/target/release/atuin.exe" >>"${GITHUB_ENV}"

  msg "Done"
}


cmd__publish() {

  msg "Creating new release"
  gh release create "v${ATUIN_TAG}" \
    --title "Atuin ${ATUIN_TAG}" \
    --notes "Automated build of Atuin $ATUIN_TAG for Windows" \
    "${ATUIN_TARGET_BIN_PATH}"

  msg "Done"
}

main() {
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  cmd="${1:-"Missing cmd. Should be one of (prep | fetch | build | publish)"}"; shift;

  if type "cmd__${cmd,,}" >/dev/null 2>&1; then
    "cmd__${cmd}" "${@}"
  else
    die "Unknown subcommand: ${cmd}"
  fi
}

main "${@}"
