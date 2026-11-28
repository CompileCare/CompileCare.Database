# Migration and release runbook

## Ownership

EF Core migrations are created and maintained in the HeapCare API Infrastructure project. This repository documents and supports deployment; it is not a parallel migration history.

## Generate a migration script

Run from a checkout of HeapCare.Api with the .NET 10 SDK and the required package feed access:

```bash
dotnet ef migrations script --idempotent \
  --project src/HeapCare.Infrastructure \
  --startup-project src/HeapCare.Api \
  --output artifacts/heapcare-migrations.sql
```

Review the generated script against the migration changes and the target database version. The script must be generated from the exact commit/release being deployed.

## Release sequence

1. Confirm the release commit, migration list and target environment.
2. Verify a recent backup and the ability to restore it; record backup identifier/time.
3. Generate the migration SQL from the release commit.
4. Review SQL for data loss, long locks, table rewrites, indexes, constraints and downtime risk.
5. Test against a fresh database and a copy/representative dataset where available.
6. Confirm compatibility with the application version currently running and the version being deployed.
7. Apply using the dedicated migration identity and approved release process. Do not run migrations automatically during API startup.
8. Verify schema/migration state and application readiness.
9. Deploy/verify application behavior and monitor errors, latency, locks and resource usage.
10. Record release, migration, approver, execution result and recovery decision.

## Safe evolution

Prefer expand/contract:
- Add nullable columns, new tables or compatible indexes first.
- Deploy code that can work with both old and new schema where rolling deployment is required.
- Backfill in bounded batches with progress and observability.
- Switch application behavior.
- Remove old schema only in a later release after verifying no consumers remain.

Never edit a migration that has already been applied to a shared environment. Create a new migration to correct it. For destructive migrations, require explicit impact assessment and a verified recovery strategy.

## Rollback

Database rollback is not assumed to be equivalent to application rollback. Before a release, define whether recovery is:
- forward-fix,
- reversible migration,
- restore from backup/PITR, or
- a combination.

Document expected data loss and downtime for the selected recovery method. A migration that irreversibly transforms or deletes data must have a reviewed recovery plan before approval.


## Pull-request migration rehearsal

HeapCare.Api now runs a PostgreSQL 16 migration rehearsal for pull requests that change the API, EF Infrastructure or migration workflow. See the [migration-rehearsal workflow](https://github.com/HeapCare/HeapCare.Api/blob/main/.github/workflows/migration-rehearsal.yml) and [implementation PR #73](https://github.com/HeapCare/HeapCare.Api/pull/73).

The job creates disposable `heapcare_upgrade` and `heapcare_fresh` databases. It checks out the PR base revision, applies its committed migrations to the upgrade database, builds the PR revision, generates its idempotent migration script, and applies that script to both databases. It reapplies the script to each database to verify idempotency, then compares the exact ordered EF migration IDs recorded in both `__EFMigrationsHistory` tables. The job uses synthetic/empty databases only and never connects to a shared or production environment.

A passing rehearsal demonstrates that the committed migration chain can upgrade the current base schema and initialize a fresh schema under PostgreSQL 16. It does **not** validate production-volume lock behavior, representative-data backfills, provider-specific physical backups/PITR, RPO/RTO, production secrets, or approval to deploy. The release sequence above and an isolated representative-data rehearsal remain mandatory for production changes.
