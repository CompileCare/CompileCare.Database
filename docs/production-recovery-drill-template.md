# Production PostgreSQL Recovery Plan and Drill Record

**Status:** Template — not an assertion that a provider, production database, backup schedule or recovery objective has been selected.

Complete and approve this record for each production environment before hospital-pilot or production activation. Keep provider-console identifiers and evidence references here; never include credentials, patient data, backup archives or secret values.

## 1. Environment and ownership

| Field | Approved value |
|---|---|
| Environment / region | TBD |
| Hosting provider and PostgreSQL service | TBD |
| PostgreSQL major/minor version | TBD |
| Production database identifier | TBD (identifier only) |
| Service owner | TBD |
| Primary recovery operator | TBD |
| Secondary/on-call operator | TBD |
| Security / privacy approver | TBD |
| Change / incident record | TBD |

## 2. Recovery objectives and policy

| Control | Required approved value | Evidence reference |
|---|---|---|
| Recovery Point Objective (RPO) | TBD | TBD |
| Recovery Time Objective (RTO) | TBD | TBD |
| Automated backup frequency | TBD | TBD |
| Full backup retention | TBD | TBD |
| WAL/PITR retention window | TBD | TBD |
| Cross-zone / cross-region strategy | TBD | TBD |
| Backup encryption at rest and in transit | TBD | TBD |
| Key owner, rotation and recovery procedure | TBD | TBD |
| Backup immutability / deletion protection | TBD | TBD |
| Backup failure and staleness alert thresholds | TBD | TBD |
| Approved backup access identities | TBD | TBD |

RPO and RTO must be approved by the hospital/business owner and translated into measurable provider settings and alert thresholds. Do not infer either objective from the weekly synthetic CI schedule or from a successful logical backup.

## 3. Provider-native configuration evidence

Record the provider's supported mechanism and exact configuration references. At minimum verify:

- Automated backups are enabled for the correct production instance/database.
- WAL archiving or provider PITR is enabled where required, with a documented recovery window.
- Backups are encrypted and key ownership, rotation, revocation and recovery are understood.
- Backup copies meet approved availability-zone/region and residency requirements.
- Retention and deletion protection meet the approved policy.
- Monitoring alerts on failed jobs, missing backups, WAL/archive gaps, storage exhaustion and recovery-window degradation.
- Runtime and backup identities use least privilege and do not share migration/admin credentials.
- Network paths for restore operations are private and restricted.
- Provider status, service limits, restore prerequisites and escalation contacts are recorded.

| Provider control | Configuration / resource reference | Verification date | Verified by | Evidence |
|---|---|---|---|---|
| Automated backup | TBD | TBD | TBD | TBD |
| PITR / WAL retention | TBD | TBD | TBD | TBD |
| Encryption / key management | TBD | TBD | TBD | TBD |
| Cross-zone/region copy | TBD | TBD | TBD | TBD |
| Retention / immutability | TBD | TBD | TBD | TBD |
| Failure / freshness alerts | TBD | TBD | TBD | TBD |
| Restore permissions / network | TBD | TBD | TBD | TBD |

## 4. Restore drill procedure

Run a provider-native restore into an isolated, access-restricted target. Never test by overwriting production.

1. Open a change/incident record and name the drill lead, operator, observer and approver.
2. Select a recovery point and record its provider identifier and timestamp (UTC).
3. Confirm the target is isolated from production traffic, outbound integrations and real patient notifications.
4. Restore using the documented provider workflow and least-privilege recovery identity.
5. Record restore start/end timestamps and any manual intervention.
6. Verify PostgreSQL version/extension compatibility, database availability, schema/migration state and critical constraints.
7. Run approved application smoke tests using synthetic or appropriately protected test identities. Do not copy production patient data to an uncontrolled environment.
8. Verify tenant boundaries and representative read/write transactions without disclosing patient content in logs.
9. Record measured recovery point/data-loss window and total recovery duration.
10. Obtain technical and business approval before any production cutover. A drill must not alter production routing.
11. Securely dispose of the temporary restore target according to the approved data-handling policy.
12. Record findings, corrective actions, owners and due dates; repeat failed steps before declaring the drill successful.

## 5. Drill evidence record

| Field | Result |
|---|---|
| Drill date and environment | TBD |
| Change / incident reference | TBD |
| Recovery point identifier | TBD |
| Recovery point timestamp (UTC) | TBD |
| Restore start (UTC) | TBD |
| Restore completed (UTC) | TBD |
| Measured RPO | TBD |
| Measured RTO | TBD |
| Schema / migration validation | TBD |
| Application smoke-test result | TBD |
| Tenant-isolation test result | TBD |
| Data-handling / cleanup result | TBD |
| Deviations and corrective actions | TBD |
| Operator / observer / approver | TBD |
| Evidence location (restricted) | TBD |
| Outcome | Not run |

Evidence should contain timestamps, non-sensitive resource identifiers, test outcomes and sanitized logs. Never attach database dumps, patient records, passwords, tokens, private keys or unrestricted provider-console exports to this repository or a public issue.

## 6. Production activation gate

Production/pilot recovery readiness remains **NOT APPROVED** until all of the following are evidenced and approved:

- [ ] Provider and production topology selected.
- [ ] RPO/RTO and retention approved by accountable hospital/business and technical owners.
- [ ] Provider-native automated backups and PITR/WAL configuration enabled and verified.
- [ ] Encryption, key ownership, key recovery and access controls approved.
- [ ] Backup immutability, residency and cross-region policy approved where applicable.
- [ ] Backup freshness/failure alerts tested.
- [ ] Successful provider-native restore drill completed in an isolated target.
- [ ] Measured RPO/RTO meet approved objectives.
- [ ] Application, schema and tenant-isolation checks pass on the restored target.
- [ ] Cleanup, incident escalation and production cutover procedures reviewed.
- [ ] Outstanding drill findings have owners and acceptable disposition.

The repository's synthetic PostgreSQL Docker workflow and logical backup helpers are useful regression controls, but they do not satisfy this gate.