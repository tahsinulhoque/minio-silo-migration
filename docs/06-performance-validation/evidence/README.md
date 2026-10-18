# DEV-922: MinIO Performance Validation — Local Storage vs NFS

## 1. Objective

Evaluate MinIO performance using local storage and compare it with NFS-backed storage under equivalent test conditions.

The benchmark will measure throughput, operation latency, and data integrity using controlled test objects.

## 2. Environment

- Host OS: Windows with Docker Desktop
- Container runtime: Docker Engine
- Orchestration: Docker Compose
- MinIO image: `dappros/minio` (pinned digest)
- Available Docker resources: 8 CPUs and approximately 3.68 GiB RAM
- MinIO container memory limit: 1 GiB
- Local storage: Docker named volume
- NFS storage: Pending environment verification

## 3. Benchmark Plan

### Test A — Local Storage Baseline

1. Verify MinIO health and storage configuration.
2. Use a dedicated benchmark bucket and synthetic test objects.
3. Record object sizes, upload/download duration, throughput, and checksums.
4. Repeat tests under the same conditions.
5. Save raw results and environment details in `evidence/`.

### Test B — NFS Storage

1. Verify that an accessible NFS server and export are available.
2. Document the NFS protocol, mount configuration, and network conditions.
3. Use an isolated test deployment and dedicated storage.
4. Repeat the same workload used for the local baseline.
5. Record results and compare them with the local baseline.

**Status:** Pending NFS environment verification.

## 4. Metrics

- Upload throughput (MiB/s)
- Download throughput (MiB/s)
- Operation duration
- Data integrity (SHA-256 where applicable)
- MinIO health and error logs

## 5. Test Controls

- Use synthetic, non-sensitive test data.
- Keep object sizes, test counts, and workload consistent.
- Record the Docker resource limits and storage configuration.
- Avoid running multiple heavy benchmarks concurrently.
- Do not treat a single run as a conclusive performance result.

## 6. Current Limitations

- Docker currently reports only the `local` volume plugin.
- A Windows drive being available does not establish that NFS is configured.
- NFS availability and mount compatibility remain unverified.
- No comparative performance results have been collected yet.
- Results from a Docker named volume must not be described as native disk performance without further verification.

## 7. Evidence

Store benchmark scripts, raw measurements, configuration details, and verification results in:

`docs/06-performance-validation/evidence/`

## 8. Conclusion

DEV-922 is in progress. The local-storage baseline and NFS comparison must be measured before drawing conclusions about performance differences.