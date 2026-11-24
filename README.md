# CompileCare.Database

Database deployment, operational tooling, environment setup and database lifecycle documentation for CompileCare.

## Ownership boundaries

- **CompileCare.Api / Infrastructure** owns EF Core entities, DbContext, model configuration, migrations and the migration model snapshot.
- **CompileCare.Database** owns database operations documentation, environment provisioning guidance, reviewed deployment artifacts, backup/restore procedures, operational scripts and (when needed) non-application database objects that have a clearly documented owner.
- Application schema changes must not be duplicated as hand-maintained SQL in this repository. Generated migration scripts are produced from the API's committed EF Core migrations.

CompileCare currently uses PostgreSQL with Npgsql and EF Core 10. The API does **not** apply migrations automatically at startup.

## Start here

- [Database architecture and ownership](docs/architecture.md)
- [Migration and release runbook](docs/migrations-and-release.md)
- [Backup and restore runbook](docs/backup-restore.md)
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

This repository is establishing its operational foundation. It does not yet contain production deployment scripts or backup automation. Those will be added as separately reviewed milestones and validated against the actual deployment platform.
