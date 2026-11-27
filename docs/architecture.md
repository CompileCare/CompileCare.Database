# Database architecture and ownership

## Current technology

The HeapCare API foundation uses PostgreSQL, Npgsql and EF Core 10. The API Infrastructure project contains the persistence implementation and the migration history.

## Source of truth

| Artifact | Owner | Source of truth |
|---|---|---|
| Entities and persistence model | API / Infrastructure | Application source |
| EF Core migrations and snapshot | API / Infrastructure | Committed migration files |
| Generated migration SQL | Release process | Generated from migrations for a release |
| Database provisioning and environment guidance | HeapCare.Database | This repository |
| Operational scripts | HeapCare.Database | Reviewed, versioned scripts |
| Runtime secrets and credentials | Environment/secret manager | Never Git |

Avoid maintaining a second schema definition in this repository. If a SQL object cannot be represented cleanly in EF migrations, document its ownership and deployment ordering, and include a reversible or recovery strategy where possible.

## Environments

Environment names and infrastructure details are intentionally deployment-neutral until the hosting platform is selected and documented.

Each environment should have:
- An isolated database and credentials.
- Network restrictions and least-privilege access.
- A separate migration identity from the runtime identity.
- Encryption in transit and at rest according to the hosting platform.
- Monitoring for availability, storage, connections, locks, replication (if applicable), and backup freshness.
- A documented restore target and owner.

## Credentials

- Runtime identity: only permissions needed by the application at runtime.
- Migration identity: schema-change permissions, used only by release tooling.
- DBA/bootstrap identity: tightly controlled, audited, and not stored in application configuration.
- Test identity: confined to disposable integration-test databases.

Never share production credentials with developers or CI. Use secret managers or protected CI secrets and rotate credentials following the platform's process.

## Tenant data

Tenant isolation is enforced by the application and database design; database credentials alone are not a tenant boundary. Avoid ad hoc queries that bypass tenant-aware data access. Any operational query involving patient or tenant data must be authorized, minimized, audited where applicable and use approved procedures.
