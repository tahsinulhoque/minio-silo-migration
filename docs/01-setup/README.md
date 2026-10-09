# DEV-917: Local MinIO and Silo Lab Setup

## Goal
Prepare a local Docker Compose environment to begin testing MinIO-to-Silo migration.

## Environment
- OS: Windows
- Container runtime: Docker Desktop
- Docker Engine: 29.2.0
- Docker Compose: v5.0.2
- MinIO tag: `RELEASE.2025-09-07T16-13-09Z` (third-party mirror: `dappros/minio`)
- Silo tag: `RELEASE.2026-09-16T00-00-00Z` (`pgsty/silo`)
- Docker network: `migration-net`

## Work Completed
- Created project documentation and evidence folders.
- Downloaded MinIO and Silo images and saved image-inspection JSON.
- Created the `migration-net` Docker network.
- Validated both Compose configurations.
- Started MinIO and Silo containers.
- Logged in to both web consoles.
- Created a `migration-test` bucket on each system.
- Uploaded `migration-test.txt` to both systems manually.

## Initial Test Result

| Check | Result |
|---|---|
| MinIO console login | PASS |
| Silo console login | PASS |
| Bucket created on both systems | PASS |
| Test file size | 43 bytes locally and in both consoles |
| Automatic replication | NOT TESTED |
| Checksum parity | NOT TESTED |

## Important Limitations
The MinIO image was pulled from a third-party mirror. Its equivalence to the original upstream image has not been independently verified.

The test file was uploaded manually to both systems. Matching file sizes do not prove matching content or automatic replication.

## Next Steps
- Verify image identity and pinned digests.
- Verify object content with checksums.
- Investigate and document client-tool registry access issues.
- Test MinIO-to-Silo replication.
- Capture reproducible commands and raw evidence.

## Cleanup Warning
Do not run `docker compose down -v` while data must be preserved; it deletes Compose-managed volumes.