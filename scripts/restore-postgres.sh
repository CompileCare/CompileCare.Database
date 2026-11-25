#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: restore-postgres.sh <archive-path> <new-target-database>" >&2
  exit 2
fi

archive_input=$1
target_database=$2

# Restrict names passed to createdb to a conservative PostgreSQL identifier form.
if [[ ! "$target_database" =~ ^[A-Za-z_][A-Za-z0-9_]{0,62}$ ]]; then
  echo "Target database must be a simple PostgreSQL identifier (1-63 characters)." >&2
  exit 2
fi

command -v pg_restore >/dev/null
command -v psql >/dev/null
command -v createdb >/dev/null
command -v sha256sum >/dev/null
command -v base64 >/dev/null

archive_directory=$(cd -- "$(dirname -- "$archive_input")" && pwd)
archive_name=$(basename -- "$archive_input")
archive_path="$archive_directory/$archive_name"
checksum_file="$archive_path.sha256"
manifest_file="$archive_path.manifest"

if [[ ! -f "$archive_path" || ! -r "$archive_path" ]]; then
  echo "Backup archive does not exist or is not readable." >&2
  exit 1
fi
if [[ ! -f "$checksum_file" || ! -f "$manifest_file" ]]; then
  echo "Backup checksum or manifest is missing; refusing restore." >&2
  exit 1
fi

source_database_base64=$(awk -F= '$1 == "source_database_base64" { print substr($0, index($0, "=") + 1); exit }' "$manifest_file")
if [[ -z "$source_database_base64" ]]; then
  echo "Backup manifest does not identify its source database." >&2
  exit 1
fi
source_database=$(printf '%s' "$source_database_base64" | base64 --decode)

if [[ "$source_database" == "$target_database" ]]; then
  echo "Refusing to restore a database into itself; choose a new target database." >&2
  exit 1
fi

if ! (cd -- "$archive_directory" && sha256sum --check --strict --status "$archive_name.sha256"); then
  echo "Backup checksum validation failed; refusing restore." >&2
  exit 1
fi

pg_restore --list "$archive_path" >/dev/null

database_exists=$(psql -X -qAt -v ON_ERROR_STOP=1 -v target="$target_database" \
  --dbname=postgres \
  --command="SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'target');")

if [[ "$database_exists" == "t" ]]; then
  echo "Target database already exists; refusing to overwrite it." >&2
  exit 1
fi

createdb --maintenance-db=postgres "$target_database"

# One transaction prevents a partially applied logical restore. The new target
# database is intentionally retained if restore fails so an operator can inspect it.
pg_restore --exit-on-error --single-transaction --no-owner --no-acl \
  --dbname="$target_database" "$archive_path"

psql -X -v ON_ERROR_STOP=1 --dbname="$target_database" --command="SELECT 1;" >/dev/null
printf 'Restored logical backup into new database: %s\n' "$target_database"
