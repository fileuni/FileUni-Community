#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <artifacts-dir> <output-dir> <plain|upx>" >&2
  exit 1
fi

artifacts_dir="$1"
output_dir="$2"
variant="$3"

mkdir -p "${output_dir}"

case "${variant}" in
  plain)
    artifact_suffix=""
    binary_pattern="fileuni"
    archive_pattern="*.tar.xz"
    ;;
  upx)
    artifact_suffix="-upx"
    binary_pattern="fileuni-upx"
    archive_pattern="*.upx.tar.xz"
    ;;
  *)
    echo "Unsupported variant: ${variant}" >&2
    exit 1
    ;;
esac

copy_binary() {
  local artifact_name="$1"
  local docker_arch="$2"
  local source_path=""
  local artifact_dir="${artifacts_dir}/${artifact_name}${artifact_suffix}"

  source_path="$(find "${artifact_dir}" -type f -name "${binary_pattern}" | head -1 || true)"
  if [ -z "${source_path}" ]; then
    local archive_path=""
    archive_path="$(find "${artifact_dir}" -type f -name "${archive_pattern}" | head -1 || true)"
    if [ -n "${archive_path}" ]; then
      local tmp_dir=""
      tmp_dir="$(mktemp -d)"
      tar -xJf "${archive_path}" -C "${tmp_dir}"
      source_path="$(find "${tmp_dir}" -type f -name "${binary_pattern}" | head -1 || true)"
    fi
  fi

  if [ -z "${source_path}" ]; then
    local zip_path=""
    zip_path="$(find "${artifact_dir}" -type f -name '*.zip' | head -1 || true)"
    if [ -n "${zip_path}" ]; then
      local tmp_dir=""
      tmp_dir="$(mktemp -d)"
      if command -v unzip >/dev/null 2>&1; then
        unzip -q "${zip_path}" -d "${tmp_dir}"
      elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "${zip_path}" "${tmp_dir}"
      else
        echo "Need unzip or python3 to extract ${zip_path}" >&2
        exit 1
      fi
      source_path="$(find "${tmp_dir}" -type f -name "${binary_pattern}" | head -1 || true)"
    fi
  fi

  if [ -z "${source_path}" ] || [ ! -f "${source_path}" ]; then
    echo "Missing ${binary_pattern} binary in artifact ${artifact_name}${artifact_suffix}" >&2
    exit 1
  fi

  install -Dm0755 "${source_path}" "${output_dir}/${docker_arch}/fileuni"
}

copy_binary "cli-x86_64-unknown-linux-musl" "amd64"
copy_binary "cli-i686-unknown-linux-musl" "386"
copy_binary "cli-aarch64-unknown-linux-musl" "arm64"
copy_binary "cli-armv7-unknown-linux-musleabihf" "armv7"
