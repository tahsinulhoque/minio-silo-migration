# DEV-925: Live Traffic and Parity Verification

## 1. Live Workload Test

- Duration: 60 seconds
- Operation: PUT
- Total requests: 117
- Failed requests: 0
- Average request latency: 155.73 ms
- Maximum request latency: 324.4 ms
- Result: PASS

Raw request log: `evidence/live-traffic.csv`

## 2. Replication Status

- Replicated objects: 117
- Replication queue: 0
- Replication errors: 0
- Average reported replication latency: 4 ms
- Maximum reported replication latency: 117 ms
- Link status: Online
- Total link downtime: 0 ms

## 3. Limitations and Pending Tests

- Average and p95 replication lag measurement.
- Time to convergence after workload stops.
- Mixed workload: overwrites, deletes, versioned writes, multipart uploads and tag changes.
- Failure injection and recovery testing.
- Full manifest parity: versions, delete markers, checksums, tags, metadata, retention and legal hold.
- Deliberate-difference detection and resync repair.
- SDK retry results and random SDK read verification.

## 4. Conclusion

The initial 60-second PUT workload completed with 117 successful requests and zero reported failures. Replication status showed 117 replicated objects, zero queued objects and zero errors.

This is initial workload evidence only. DEV-925 acceptance criteria are not yet fully satisfied.
