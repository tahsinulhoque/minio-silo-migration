# DEV-925: Live Traffic and Source–Silo Parity Verification

## 1. Objective

The objective of this task is to validate replication between the source MinIO and target Silo while the source continues receiving traffic.

This verification covers:
- Live traffic through the migration proxy.
- Target-side failure and recovery.
- Source restart behavior.
- Object and version parity.
- Tags and user metadata comparison.
- Versioning and encryption configuration.
- Deliberate mismatch detection and repair.

The source MinIO remains authoritative during this validation.

## 2. Environment

| Component | Configuration |
|---|---|
| Source | MinIO |
| Target | Silo |
| Deployment | Local Docker Compose |
| Network | migration-net |
| Proxy | Nginx |
| Proxy endpoint | 127.0.0.1:9300 |
| Test bucket | feature-validation |
| Replication | MinIO to Silo |

## 3. Live Traffic Test

A continuous PUT workload was executed through the Nginx proxy.

### Initial workload

| Metric | Result |
|---|---:|
| Duration | 60 seconds |
| Requests | 117 |
| Failed requests | 0 |
| Average latency | 155.73 ms |
| Maximum latency | 324.40 ms |

### Failure recovery workloads

| Scenario | Duration | Requests | Failed | Average latency | Max latency |
|---|---:|---:|---:|---:|---:|
| Silo stop/restart | 120 sec | 159 | 0 | 296.81 ms | 986.48 ms |
| Network disconnect | 120 sec | 219 | 0 | 175.93 ms | 535.30 ms |
| Source restart followed by workload | 120 sec | 233 | 0 | 152.63 ms | 286.09 ms |

All recorded workload requests completed without reported failures.

**Note:** The source restart occurred before its associated 120-second workload. Therefore, this result does not prove zero failed requests during the actual restart interval.

Raw evidence:
- `evidence/live-traffic.csv`
- `evidence/silo-stop-recovery.txt`
- `evidence/network-disconnect-recovery.txt`
- `evidence/source-restart-recovery.txt`

## 4. Replication Recovery Results

### Silo stop/restart

- Silo was stopped while source traffic continued.
- Silo was restarted.
- Replication returned online.
- Replication queue returned to zero.
- Replication errors: 0.
- Reported link downtime: 48 seconds.

### Network disconnect/reconnect

- Silo was disconnected from `migration-net`.
- Source workload continued through the proxy.
- Silo was reconnected.
- Replication returned online.
- Replication queue returned to zero.
- Replication errors: 0.
- Reported link downtime: 48 seconds.

### Source restart

- Source MinIO was restarted.
- Proxy connectivity was checked.
- A subsequent 120-second workload completed with 233 requests and zero reported failures.
- Replication returned online with zero queued objects and zero errors.

## 5. Replication Lag Measurement

A 20-object workload was uploaded to the source bucket.

| Metric | Result |
|---|---:|
| Total writes | 20 |
| Objects found on Silo | 20 |
| Missing objects | 0 |

The initial measurement script calculated elapsed time from upload until a later polling phase. Therefore, its values are not valid per-object replication lag measurements.

Average and P95 replication lag, measured using upload-to-replication timestamps, remain unverified.

## 6. Source–Silo Parity Verification

### 6.1 Object comparison

Command:

`mc diff local/feature-validation silo/feature-validation`

The initial comparison returned no differences.

After the deliberate mismatch test and repair, the final comparison also returned no differences.

### 6.2 Version comparison

Version listings were compared using:

`mc ls --versions --recursive local/feature-validation`

`mc ls --versions --recursive silo/feature-validation`

The displayed version listings matched, including:
- Version IDs.
- Multiple versions of `mixed/new-write.txt`.
- Multiple versions of `mixed/versioned.txt`.
- The delete marker associated with `mixed/versioned.txt`.
- The 70 MiB multipart-test object.

### 6.3 Object tags

Source and Silo tags for `mixed/new-write.txt` matched.

| Tag | Value |
|---|---|
| env | dev |
| test | 925 |

### 6.4 User metadata

Source and Silo metadata for `mixed/new-write.txt` matched.

| Field | Source | Silo |
|---|---|---|
| Size | 21 bytes | 21 bytes |
| ETag | Same | Same |
| Version ID | Same | Same |
| Content-Type | text/plain | text/plain |
| Tagging count | 2 | 2 |

Silo also returned a CRC64NVME checksum.

### 6.5 Versioning

Both buckets reported versioning enabled.

Commands:

`mc version info local/feature-validation`

`mc version info silo/feature-validation`

Result: Versioning enabled on both sides.

### 6.6 Retention and Legal Hold

The retention information command returned an Object Lock unsupported error for both buckets.

Therefore:
- Retention parity: Not verified.
- Legal Hold parity: Not verified.

### 6.7 Encryption

The encryption information command returned:

`The server side encryption configuration was not found.`

This result was observed on both source and Silo.

Result: Neither bucket reported a server-side encryption configuration.

## 7. Deliberate Difference Detection and Repair

A deliberate mismatch was introduced by deleting `mixed/new-write.txt` from the Silo target.

Silo created a delete marker while the source object remained available.

The comparison command detected the mismatch:

`mc diff local/feature-validation silo/feature-validation`

Detected difference:

`mixed/new-write.txt`

### Resync attempt

Replication resync was started using the configured remote target ARN.

Command:

`mc replicate resync start --remote-bucket "arn:minio:replication::45459951-f4c0-403b-b0c1-88fd3d786211:feature-validation" local/feature-validation`

Resync status:

| Metric | Result |
|---|---:|
| Status | Completed |
| Replicated objects | 776 |
| Replicated size | 70 MiB |
| Failed objects | 0 |

However, the missing object was still absent from the Silo bucket after resync.

### Manual repair

The source object was copied directly to Silo:

`mc cp local/feature-validation/mixed/new-write.txt silo/feature-validation/mixed/new-write.txt`

The copy completed successfully.

Final comparison:

`mc diff local/feature-validation silo/feature-validation`

Result: No differences returned.

**Important:** The deliberate mismatch was detected and repaired through manual object copy. Automatic resync did not restore the missing object.

## 8. Known Limitations and Pending Verification

The following acceptance criteria are not fully verified yet:

1. Accurate average and P95 replication lag measurement.
2. Convergence time after workload stops.
3. Full manifest comparison covering every object and version.
4. Full checksum verification across the dataset.
5. Random SDK read verification from Silo.
6. Retention and Legal Hold parity.
7. Encryption state parity beyond checking the absence of SSE configuration.
8. Zero failed requests during the actual source restart interval.
9. Automatic resync repair of the deliberately deleted target object.
10. Full mixed workload through the proxy, including overwrite, delete, versioned writes, tags and multipart uploads.

## 9. Conclusion

DEV-925 has demonstrated live source traffic through the proxy, recovery from Silo-side failures and network disconnection, and basic object-level parity between MinIO and Silo.

Version listings, tags, selected user metadata, versioning configuration and encryption configuration were compared.

A deliberate object mismatch was detected using `mc diff` and repaired through manual copy.

However, full manifest parity, accurate replication lag measurement, retention/legal hold validation, SDK verification and automatic resync repair remain outstanding.

**DEV-925 should not be marked fully complete until the remaining acceptance criteria have been addressed.**

## 10. Additional Replication Lag Measurement

A 10-object workload was uploaded through the migration proxy. Each object was checked on Silo immediately after its source upload.

| Metric | Result |
|---|---:|
| Total writes | 10 |
| Replicated objects | 10 |
| Missing objects | 0 |
| Average observed latency | 324.45 ms |
| P95 observed latency | 397.19 ms |
| Maximum observed latency | 397.19 ms |

Note: These values represent upload-to-target-visibility latency, not isolated replication processing latency.

## 11. Current Object Manifest Comparison

Recursive JSON listings were collected from both source MinIO and Silo using `mc ls --recursive --json`.

Compared fields:
- Object keys
- Object sizes
- ETags

The displayed source and target entries matched, including:
- `live-traffic-93.txt` through `live-traffic-99.txt`
- `mixed/new-write.txt`
- `mixed/multipart-70mb.bin`
- `version-test.txt`

The 70 MiB object had matching size and ETag on both sides.

Result: No differences were observed in the displayed current-object manifest entries.

Note: This is not a complete version-history manifest or a full-dataset checksum verification.

## 12. Random SDK Read and SHA256 Verification

The MinIO Python SDK was used to read selected objects independently from the source MinIO and Silo endpoints.

SHA256 checksums were calculated locally for each downloaded object.

| Object | Source and Silo SHA256 |
|---|---|
| `live-traffic-99.txt` | MATCH |
| `mixed/new-write.txt` | MATCH |
| `mixed/multipart-70mb.bin` | MATCH |

All three selected objects returned identical SHA256 checksums.

Result: 3 of 3 selected SDK reads passed checksum comparison.

This is sample-based verification and does not represent a full-dataset checksum audit.

## 13. Remaining Limitations

- Full-dataset checksum verification remains pending.
- Full version-history manifest comparison remains pending.
- Retention and Legal Hold could not be validated because Object Lock is not enabled/supported on the tested buckets.
- The deliberate mismatch was repaired through manual object copy; automatic resync did not restore the missing object.
- The measured upload-to-target-visibility latency is not an isolated replication lag metric.

## Full Dataset SHA256 Checksum Verification

A full current-object checksum comparison was performed between the source MinIO and target Silo using the MinIO Python SDK.

| Metric | Result |
|---|---:|
| Source objects | 266 |
| Silo objects | 266 |
| Missing objects on Silo | 0 |
| Extra objects on Silo | 0 |
| Checksum mismatches | 0 |

**Result: PASS**

All 266 current objects were present on both sides, with no missing objects, extra objects, or SHA256 checksum mismatches.

Note: This verification covers current objects, not every historical object version or delete marker.


### Accurate Replication Visibility Measurement

A defined workload of 10 PUT requests was executed through the Nginx proxy while replication was active. Each object was checked individually on Silo after its source upload completed.

| Metric | Result |
|---|---:|
| Total writes | 10 |
| Replicated objects | 10 |
| Missing objects | 0 |
| Average visibility latency | 151.89 ms |
| P95 visibility latency | 227.86 ms |

**Result:** All 10 objects became visible on Silo.

Note: These measurements represent upload-completion-to-target-visibility latency, not isolated replication processing latency. The convergence time after the final write was not independently measured and remains pending.


## 14. Post-Load Visibility and Convergence Check

A post-load visibility check was performed against the 10 objects created during the accurate replication visibility measurement.

The check used the following object naming pattern:

`accurate-lag-1.txt` through `accurate-lag-10.txt`

| Metric | Result |
|---|---:|
| Total objects checked | 10 |
| Objects visible on Silo | 10 |
| Missing objects | 0 |
| Check duration | 2,355.83 ms |
| Result | ALL VISIBLE |

All 10 previously uploaded objects were found on Silo.

**Important limitation:** The measured 2,355.83 ms is the duration of the post-load visibility check. It is not the actual time to convergence after the final source write, because the final write timestamp was not retained for this check.

Therefore, the exact load-stop-to-convergence time remains unverified.

## 15. Updated Replication Visibility Metrics

The latest 10-write measurement produced the following results:

| Metric | Result |
|---|---:|
| Total writes | 10 |
| Replicated objects | 10 |
| Average upload-to-visibility latency | 151.89 ms |
| P95 upload-to-visibility latency | 227.86 ms |
| Missing objects | 0 |

These values represent upload-completion-to-target-visibility latency, not isolated replication processing latency.

