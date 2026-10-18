# DEV-922: MinIO Performance Validation — Local Storage vs NFS

## 1. Objective

Measure MinIO upload/download performance using the current local Docker storage setup and compare it with NFS-backed storage when an NFS environment becomes available.

## 2. Environment

- Host OS: Windows with Docker Desktop
- Orchestration: Docker Compose
- MinIO image: pinned `dappros/minio` image
- MinIO version: `RELEASE.2025-09-07T16-13-09Z`
- Docker resources: 8 CPUs and approximately 3.68 GiB RAM
- MinIO container memory limit: 1 GiB
- Storage: Docker-backed local volume
- MinIO topology: single node, single drive

## 3. Local Benchmark Results

Test object size: 10 MiB (10,485,760 bytes)

| Operation | Duration | Throughput | Notes |
|---|---:|---:|---|
| Upload run 1 | 4.624 s | 2.16 MiB/s | End-to-end, includes Docker copy |
| Download run 1 | 4.217 s | 2.37 MiB/s | End-to-end, includes Docker copy |
| Upload run 2 | 3.984 s | 2.51 MiB/s | Stopwatch includes Docker Compose command overhead |
| Upload run 2 | Not independently timed | 49.87 MiB/s | Speed reported by `mc` |

These measurements use different timing methods and must not be treated as directly comparable. They are preliminary observations, not a definitive storage performance benchmark.

## 4. Data Integrity

- Original and downloaded test file SHA-256 matched.
- The second uploaded object was downloaded to Windows and its SHA-256 matched the original file.
- Integrity result: PASS for the verified objects.

## 5. NFS Comparison Status

**Status: BLOCKED / PENDING**

The NFS comparison could not be executed because an accessible NFS server/export has not been identified.

Environment checks:
- Windows `ClientForNFS-Infrastructure`: Disabled
- No NFS-related Windows services were returned by `Get-Service *NFS*`
- Docker reports only the `local` volume plugin
- NFS mount utilities were not found in the MinIO container

These checks do not prove that NFS is impossible; they show that the required NFS test environment is not currently available or verified.

## 6. Limitations

- Only a small 10 MiB test object was used.
- The number of benchmark runs is limited.
- Measurements include client and container overhead.
- The test does not isolate physical disk performance.
- NFS results are unavailable, so no local-versus-NFS performance conclusion can be made.
- A repeatable benchmark with larger objects and multiple runs is still recommended.

## 7. Evidence

- `evidence/benchmark-results.txt` — recorded preliminary results and checksum verification
- Local `.bin` files — retained locally and excluded from Git tracking

## 8. Conclusion

The initial local-storage test and data-integrity checks succeeded. DEV-922 remains in progress until a suitable NFS server/export is available and the same workload can be run against NFS-backed storage.