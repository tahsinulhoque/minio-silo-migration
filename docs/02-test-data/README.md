# DEV-918: Test Data and Verification Toolkit

## Goal
Create a small test object and verify its integrity using SHA-256 checksums.

## Environment
- OS: Windows
- Shell: PowerShell
- Storage systems: MinIO and Silo, running locally through Docker Compose

## Procedure
1. Created `test-object-01.txt` with the content `DEV-918 test object`.
2. Recorded the local file size and SHA-256 hash.
3. Uploaded the file manually to the `migration-test` bucket in MinIO.
4. Uploaded the same file manually to the `migration-test` bucket in Silo.
5. Downloaded both objects and compared their SHA-256 hashes.

## Results
- Local test file size: 24 bytes
- MinIO and Silo downloaded file contents: matched
- SHA-256 comparison: PASS, based on the user's reported matching hashes
- Automatic replication: NOT TESTED

## Limitations
The objects were uploaded manually to each storage system. This test verifies downloaded content integrity only; it does not demonstrate automatic replication or zero-downtime migration.

## Evidence
- `evidence/test-object-01-size.txt`
- `evidence/test-object-01-sha256.txt`
- `evidence/test-object-01-verification.txt`
- `evidence/object-checksum-comparison.txt`

## Conclusion
The manual test-object integrity check passed. Automatic replication and migration validation remain separate tasks.