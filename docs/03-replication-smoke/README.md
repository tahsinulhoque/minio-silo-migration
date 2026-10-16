# DEV-919: Replication Smoke Test

## Objective

Validate replication behavior in a local Docker Compose lab using pinned MinIO and Silo images. The test covers MinIO-to-MinIO replication and an experimental MinIO-to-Silo replication path.

## Environment

- Host: Windows with Docker Desktop
- Orchestration: Docker Compose
- Source: MinIO single-node instance
- MinIO replication target: Separate MinIO instance
- Experimental target: Silo single-node instance
- Network: `migration-net`
- Test data: Synthetic text objects only

## Test 1: MinIO to MinIO

### Configuration

- Source bucket: `replication-smoke`
- Target bucket: `replication-smoke`
- Versioning: Enabled on both buckets
- Replication rule ID: `db95hb36lkks51tc7820`
- Priority: `1`

### Procedure

1. Created the source and target buckets.
2. Enabled versioning on both buckets.
3. Added a replication rule from the source bucket to the target bucket.
4. Uploaded a synthetic test object to the source.
5. Checked the target for the replicated object.
6. Verified replication status and compared SHA-256 checksums.

### Result

**PASS — smoke test**

The test object was replicated to the target. The source reported `Replication Status: COMPLETED`, and the source and target SHA-256 checksums matched.

## Test 2: MinIO to Silo

### Configuration

- Source bucket: `silo-replication-smoke`
- Target bucket: `silo-replication-smoke`
- Versioning: Enabled on both buckets
- Replication rule ID: `silo-smoke`
- Priority: `1`
- Target alias: `silo`

### Procedure

1. Created separate source and target buckets.
2. Enabled versioning on both buckets.
3. Added a replication rule targeting Silo.
4. Uploaded the synthetic object `silo-test.txt` to the source.
5. Confirmed the source object and inspected the target object.
6. Compared SHA-256 checksums from source and target.

### Result

**PASS — observed smoke test**

The source object reported `Replication Status: COMPLETED`. The target object was present, and its SHA-256 checksum matched the source checksum.

This confirms that the tested object replicated successfully in this lab configuration. It does not establish full compatibility for every Silo feature, workload, or failure scenario.

## Limitations

- This was a local, single-node smoke test using synthetic data.
- It was not a production migration or a zero-downtime acceptance test.
- Live traffic, sustained workloads, failure injection, large-object transfer, deletion/version replication, and rollback were not validated here.
- The results apply only to the pinned images and configuration used during this test.
- MinIO-to-Silo behavior must be tested further before making broader compatibility claims.

## Evidence

Save relevant command output and screenshots in:

- `docs/03-replication-smoke/evidence/`
- `docs/03-replication-smoke/screenshots/`

Evidence should include the replication rule listing, source upload result, target object details, replication status, and matching SHA-256 outputs.

## Conclusion

Both MinIO-to-MinIO and MinIO-to-Silo object replication passed the observed smoke tests, including matching SHA-256 checksums. Further testing is required before treating the setup as production-ready or zero-downtime capable.
