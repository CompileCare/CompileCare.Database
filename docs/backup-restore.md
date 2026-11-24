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
