# Database operations checklist

Use this checklist when provisioning an environment or preparing for production readiness.

## Provisioning
- [ ] Database engine/version is supported and recorded.
- [ ] Database is isolated per environment.
- [ ] Runtime, migration and administrative identities are separated.
- [ ] Network access is restricted to approved application/release/operations paths.
- [ ] TLS and platform encryption-at-rest settings are verified.
- [ ] Credentials are stored in an approved secret manager.
- [ ] Connection limits and pool sizing are reviewed with the application.
- [ ] Time zone and maintenance window are documented.
- [ ] Monitoring and alerting are configured.
- [ ] Backup and PITR policy is enabled and documented.

## Release
- [ ] Exact application release and migration set identified.
- [ ] Generated migration script reviewed.
- [ ] Backup/restore validation completed.
- [ ] Migration tested on clean and representative databases.
- [ ] Locking, index creation and data migration impact reviewed.
- [ ] Recovery strategy and approver recorded.
- [ ] Post-deployment schema and application health verified.

## Ongoing operations
- [ ] Backup freshness and failures monitored.
- [ ] Capacity, storage growth and connection pressure monitored.
- [ ] Long-running transactions, locks and slow queries reviewed.
- [ ] Access and credential rotation reviewed.
- [ ] Provider-neutral logical backup archive, checksum and manifest are validated.
- [ ] Restore into a new isolated database passes the Docker verification; evidence is retained.
- [ ] Provider-native backup/PITR, encryption/key ownership, retention, RPO/RTO and restore-test cadence are defined before production activation.
- [ ] Operational changes are ticketed/reviewed and audited.
- [ ] Any privileged access is time-bound and logged.

Items should be checked only with evidence. This document is a checklist, not proof that controls are implemented.
