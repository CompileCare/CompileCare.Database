#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: backup-postgres.sh <output-archive-path>" >&2
  exit 2
fi

if [[ -z "$(printenv PGDATABASE || true)" ]]; then
  echo "PGDATABASE must identify the source database." >&2
  exit 2
fi

command -v pg_dump >/dev/null
command -v pg_restore >/dev/null
command -v base64 >/dev/null
command -v date >/dev/null
command -v awk >/dev/null
if ! command -v sha256sum >/dev/null && ! command -v shasum >/dev/null; then
  echo "A SHA-256 utility (sha256sum or shasum) is required." >&2
  exit 2
fi

sha256_file() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

output_input=$1
output_name=$(basename -- "$output_input")
output_directory=$(dirname -- "$output_input")

if [[ -z "$output_name" || "$output_name" == "." || "$output_name" == "/" ]]; then
  echo "Output path must name an archive file." >&2
  exit 2
fi

mkdir -p -- "$output_directory"
output_directory=$(cd -- "$output_directory" && pwd)
output_archive="$output_directory/$output_name"
checksum_file="$output_archive.sha256"
manifest_file="$output_archive.manifest"

if [[ -e "$output_archive" || -e "$checksum_file" || -e "$manifest_file" ]]; then
  echo "Refusing to overwrite an existing archive or sidecar." >&2
  exit 1
fi

umask 077
temporary_archive=$(mktemp "$output_archive.tmp.XXXXXX")
temporary_checksum=$(mktemp "$checksum_file.tmp.XXXXXX")
temporary_manifest=$(mktemp "$manifest_file.tmp.XXXXXX")
created_archive=0
created_checksum=0
created_manifest=0
completed=0

cleanup() {
  rm -f -- "$temporary_archive" "$temporary_checksum" "$temporary_manifest"
  if [[ "$completed" -ne 1 ]]; then
    if [[ "$created_archive" -eq 1 ]]; then rm -f -- "$output_archive"; fi
    if [[ "$created_checksum" -eq 1 ]]; then rm -f -- "$checksum_file"; fi
    if [[ "$created_manifest" -eq 1 ]]; then rm -f -- "$manifest_file"; fi
  fi
}
trap cleanup EXIT

pg_dump --format=custom --no-owner --no-acl --file="$temporary_archive"

if [[ ! -s "$temporary_archive" ]]; then
  echo "pg_dump produced an empty archive." >&2
  exit 1
fi

pg_restore --list "$temporary_archive" >/dev/null
archive_checksum=$(sha256_file "$temporary_archive")
source_database_base64=$(printf '%s' "$PGDATABASE" | base64 | tr -d '\n')
created_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
dump_version=$(pg_dump --version)

printf '%s  %s\n' "$archive_checksum" "$output_name" > "$temporary_checksum"
{
  printf 'format=custom\n'
  printf 'source_database_base64=%s\n' "$source_database_base64"
  printf 'created_at_utc=%s\n' "$created_at_utc"
  printf 'pg_dump_version=%s\n' "$dump_version"
} > "$temporary_manifest"

chmod 600 "$temporary_archive" "$temporary_checksum" "$temporary_manifest"

# Hard links publish each file without replacing a path created concurrently.
ln -- "$temporary_archive" "$output_archive"
created_archive=1
ln -- "$temporary_checksum" "$checksum_file"
created_checksum=1
ln -- "$temporary_manifest" "$manifest_file"
created_manifest=1

completed=1
printf 'Created PostgreSQL logical backup: %s\n' "$output_archive"
printf 'Created checksum and non-secret manifest sidecars.\n'
