# HeapCare Database Operations

> **HeapCare identity:** Product-facing documentation and operational guidance in this repository use HeapCare. Existing PostgreSQL database and role names, connection-string compatibility keys, backup paths, and historical restore artifacts remain compatibility references; this repository does not rename persisted resources.

Database deployment, operational tooling, environment setup and database lifecycle documentation for HeapCare.

## Ownership boundaries

- **HeapCare.Api / Infrastructure** owns EF Core entities, DbContext, model configuration, migrations and the migration model snapshot.
- **HeapCare.Database** owns database operations documentation, environment provisioning guidance, reviewed deployment artifacts, backup/restore procedures, operational scripts and (when needed) non-application database objects that have a clearly documented owner.
- Application schema changes must not be duplicated as hand-maintained SQL in this repository. Generated migration scripts are produced from the API's committed EF Core migrations.

HeapCare currently uses PostgreSQL with Npgsql and EF Core 10. The API does **not** apply migrations automatically at startup.

## Start here

- [Database architecture and ownership](docs/architecture.md)
- [Migration and release runbook](docs/migrations-and-release.md)
- [Backup and restore runbook](docs/backup-restore.md)
- [Production recovery plan and drill record](docs/production-recovery-drill-template.md) — provider-selection-neutral approval and evidence template for RPO/RTO, backup/PITR, key management and isolated restore drills.
- [Operations and environment checklist](docs/operations-checklist.md)

## Principles

1. Use separate credentials for application runtime, migration execution and administrative/bootstrap work.
2. Never commit secrets, connection strings with passwords, patient data or production exports.
3. Production schema changes are reviewed, generated from the source migrations, tested against a representative database and applied as a release step.
4. Backups are not considered validated until restore testing succeeds.
5. Every environment has explicit ownership, retention, recovery objectives and access controls.
6. Prefer additive/expand-contract changes for deployments that may overlap application versions.
7. Destructive changes require a documented impact, recovery plan and approval.

## Status

This repository contains provider-neutral PostgreSQL logical backup/restore helpers and an isolated Docker verification workflow. These helpers are not production backup scheduling or platform-native point-in-time recovery. Production backup automation, retention, RPO/RTO and hosting-platform procedures remain separate release-readiness decisions.
