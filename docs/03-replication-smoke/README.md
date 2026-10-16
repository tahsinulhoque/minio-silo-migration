# DEV-919: Replication Smoke Test and Rehearsal

## Goal
Validate object replication behavior before attempting MinIO-to-Silo migration.

## Environment
- Docker Desktop on Windows
- MinIO source: local Docker Compose
- Silo target: local Docker Compose
- Shared Docker network: migration-net

## Test Plan
1. Configure MinIO-to-MinIO replication.
2. Upload a test object to the source.
3. Verify automatic replication to the target.
4. Record replication status, object size, and SHA-256 checksum.
5. Repeat the smoke test for MinIO-to-Silo, if supported.
6. Record errors, limitations, and evidence.

## Current Status
- Initial MinIO and Silo containers are running.
- Test buckets and manual object uploads were verified.
- Automatic replication has not yet been tested.

## Results
Pending execution.

## Evidence
Store raw command output in the `evidence/` directory and screenshots in `screenshots/`.

## Limitations
Manual uploads to both systems do not prove replication works. Cross-vendor replication compatibility must be verified experimentally.