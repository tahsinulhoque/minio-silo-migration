# DEV-924: Replication and Backfill

## Goal
Document the existing MinIO-to-Silo replication configuration and
validate the replication smoke-test object.

## Findings
- Source bucket: `local/silo-replication-smoke`
- Target bucket: `silo/silo-replication-smoke`
- Replication rule: `silo-smoke`
- Rule status: Enabled
- Delete replication: Enabled
- Delete-marker replication: Enabled
- Existing-object replication: Enabled
- `silo-test.txt` exists on both source and target (60 B).
- `mc diff` reported no object differences.
- Replication status showed 0 queued objects and 0 errors.
- Replication status reported 0 replicated objects during the
  observed period; this does not establish a complete backfill.

## Limitations
This validates the existing smoke-test object only. Full source inventory,
configuration transfer, initial backfill, version and metadata parity,
and migration-wide replication completion remain unverified.

## Conclusion
The existing smoke-test object is present on both sides, and `mc diff`
reported no differences. Do not treat this as proof of full migration
readiness.
## Additional Evidence: Feature-Validation Object Integrity

- Source object: `local/feature-validation/version-test.txt`
- Target object: `silo/feature-validation/version-test.txt`
- Object size: 102 bytes on both sides.
- Source SHA-256: `134ca695b885c0ed8d3a9b58c03448a5641dc0512d295bd2de851f3a877d2d33`
- Target SHA-256: `134ca695b885c0ed8d3a9b58c03448a5641dc0512d295bd2de851f3a877d2d33`
- Result: **PASS** — source and target object content hashes match.
- Limitation: This verifies the content of this object only. It does not prove all versions, metadata, or the full bucket inventory are identical.
