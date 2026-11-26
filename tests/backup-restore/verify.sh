#!/usr/bin/env bash
set -Eeuo pipefail

repository_root=$(cd -- "$(dirname -- "$0")/../.." && pwd)
backup_directory=/tmp/compilecare-backup-restore-test
source_database=compilecare_backup_source
restored_database=compilecare_backup_restored
existing_database=compilecare_backup_existing
corrupt_database=compilecare_backup_corrupt
archive="$backup_directory/compilecare-source.dump"
corrupt_archive="$backup_directory/compilecare-corrupt.dump"

mkdir -p -- "$backup_directory"
chmod 700 "$backup_directory"

for database in "$source_database" "$restored_database" "$existing_database" "$corrupt_database"; do
  dropdb --if-exists --maintenance-db=postgres "$database" >/dev/null
done

createdb --maintenance-db=postgres "$source_database"
psql -X -v ON_ERROR_STOP=1 --dbname="$source_database" <<'SQL'
CREATE TABLE backup_probe (
  id integer PRIMARY KEY,
  marker text NOT NULL
);
INSERT INTO backup_probe (id, marker)
VALUES (1, 'synthetic-record-001'), (2, 'synthetic-record-002');
SQL

PGDATABASE="$source_database" bash "$repository_root/scripts/backup-postgres.sh" "$archive"

actual_checksum=$(sha256sum "$archive" | awk '{print $1}')
expected_checksum=$(awk 'NR == 1 { print $1; exit }' "$archive.sha256")
if [[ "$actual_checksum" != "$expected_checksum" ]]; then
  echo "Backup checksum sidecar does not match the archive." >&2
  exit 1
fi
for sidecar in "$archive" "$archive.sha256" "$archive.manifest"; do
  mode=$(stat -c '%a' "$sidecar")
  if [[ "$mode" != "600" ]]; then
    echo "Expected restrictive mode 600 for $sidecar; received $mode." >&2
    exit 1
  fi
done
manifest_source=$(awk -F= '$1 == "source_database_base64" { print substr($0, index($0, "=") + 1); exit }' "$archive.manifest" | base64 --decode)
if [[ "$manifest_source" != "$source_database" ]] || ! grep -qx 'format=custom' "$archive.manifest"; then
  echo "Backup manifest metadata is invalid." >&2
  exit 1
fi

if PGDATABASE="$source_database" bash "$repository_root/scripts/backup-postgres.sh" "$archive" >/dev/null 2>&1; then
  echo "Backup helper unexpectedly overwrote an existing archive." >&2
  exit 1
fi

bash "$repository_root/scripts/restore-postgres.sh" "$archive" "$restored_database"
restored_count=$(psql -X -qAt -v ON_ERROR_STOP=1 --dbname="$restored_database" \
  --command="SELECT count(*) FROM backup_probe;")
if [[ "$restored_count" != "2" ]]; then
  echo "Expected two synthetic rows after restore; received $restored_count." >&2
  exit 1
fi

if bash "$repository_root/scripts/restore-postgres.sh" "$archive" "$source_database" >/dev/null 2>&1; then
  echo "Restore helper unexpectedly allowed restoration into its source database." >&2
  exit 1
fi

createdb --maintenance-db=postgres "$existing_database"
if bash "$repository_root/scripts/restore-postgres.sh" "$archive" "$existing_database" >/dev/null 2>&1; then
  echo "Restore helper unexpectedly overwrote an existing target database." >&2
  exit 1
fi

cp -- "$archive" "$corrupt_archive"
cp -- "$archive.manifest" "$corrupt_archive.manifest"
expected_checksum=$(awk '{print $1}' "$archive.sha256")
printf '%s  %s\n' "$expected_checksum" "$(basename -- "$corrupt_archive")" > "$corrupt_archive.sha256"
printf '\ncorruption-test\n' >> "$corrupt_archive"

if bash "$repository_root/scripts/restore-postgres.sh" "$corrupt_archive" "$corrupt_database" >/dev/null 2>&1; then
  echo "Restore helper unexpectedly accepted a corrupted archive." >&2
  exit 1
fi

if psql -X -qAt --dbname="$corrupt_database" --command="SELECT 1;" >/dev/null 2>&1; then
  echo "A database was created for a checksum-invalid archive." >&2
  exit 1
fi

echo "PostgreSQL logical backup/restore Docker verification passed."
