# Backup and restore runbook

> Platform-specific backup commands and automation are not yet implemented. This checklist defines the minimum operational controls before a production database is considered supported.

## Required policy decisions

- Recovery Point Objective (RPO)
- Recovery Time Objective (RTO)
- Backup frequency and retention
- Encryption and key ownership
- Backup location, access restrictions and geographic/region policy
- Point-in-time recovery (PITR) availability and retention
- Restore-test frequency and accountable owner

## Backup validation

A backup is not verified merely because the backup job reports success. Validation must include:
- Integrity/availability checks supported by the database platform.
- Restore into an isolated environment.
- Verification of schema and migration state.
- Application-level smoke tests.
- Documented restore duration and data-loss window.
- Confirmation that restored data is handled under the same privacy controls.

## Restore procedure

1. Declare incident and identify the recovery target/time.
2. Obtain required approvals and select the verified backup/PITR point.
3. Restore into an isolated target; do not overwrite the production database until the plan is approved.
4. Verify database health, migration state and critical integrity constraints.
5. Run application smoke/integration checks using a restricted test identity.
6. Review whether data after the restore point must be reconciled.
7. Approve cutover, update connection routing/secrets as required, and monitor.
8. Record incident timeline, backup source, restore point, RPO/RTO achieved and follow-up actions.

Never attach backups or exports containing patient information to issues, PRs, chat, or ordinary developer machines.


## Provider-neutral logical backup helpers

The repository scripts provide a guarded, database-level logical backup path that can be exercised before the production hosting platform is selected. They do not replace platform-managed physical backups or point-in-time recovery.

Configure PostgreSQL's standard connection environment (`PGHOST`, `PGPORT`, `PGUSER`, `PGDATABASE`) and provide credentials through an approved mechanism such as a permission-restricted `PGPASSFILE` or a secret manager. Do not put passwords in command-line arguments or commit credential files.

Create a custom-format archive:

```bash
PGHOST=db.example.internal PGPORT=5432 PGUSER=compilecare_backup PGDATABASE=compilecare \
  bash scripts/backup-postgres.sh /secure-backups/compilecare.dump
```

The helper refuses to overwrite existing output. It supports SHA-256 through `sha256sum` (GNU/Linux) or `shasum -a 256` (macOS); restore also supports the corresponding GNU and BSD base64 decode options. It creates the archive plus `.sha256` and `.manifest` sidecars with restrictive file permissions. It validates the archive with `pg_restore --list` before publishing the files. The manifest contains the source database name (base64 encoded), UTC creation time and `pg_dump` version; it does not contain credentials.

Restore into a **new, isolated database**:

```bash
PGHOST=db.example.internal PGPORT=5432 PGUSER=compilecare_restore \
  bash scripts/restore-postgres.sh /secure-backups/compilecare.dump compilecare_restore_verify
```

The restore helper verifies the checksum and archive, rejects a target that is the source database or already exists, creates a new target database and restores in a single transaction. It never drops or overwrites an existing database. If restore fails, the newly created target remains for operator inspection; the transactional restore prevents a partial set of restored objects from being committed.

### Scope and limitations

- This is a logical backup of one database, not a cluster-wide backup. Roles, role grants, server configuration and other global objects must be provisioned and backed up through separately reviewed procedures.
- The archive is generated with `--no-owner --no-acl`; restored objects are owned by the restore connection identity. Review role/privilege provisioning separately.
- A checksum detects accidental corruption; it is not a digital signature or proof of archive authenticity. Store the archive and sidecars together in an approved encrypted, access-controlled destination.
- Only restore archives from trusted sources, and always restore to an isolated target before any cutover decision.
- The Docker test uses synthetic rows in a disposable PostgreSQL 16 container. It proves the helper behavior, not production RPO/RTO, retention, PITR or hosting-provider automation.
- Do not treat a passing logical restore test as evidence that production recovery controls are complete. Define the provider-native backup/PITR mechanism, encryption/key ownership, retention, RPO, RTO, restore cadence and accountable operator before production activation.

The repository's `docker-compose.backup-test.yml` and `.github/workflows/backup-restore.yml` execute the backup, restore, checksum and overwrite-guard tests against an isolated PostgreSQL container.
