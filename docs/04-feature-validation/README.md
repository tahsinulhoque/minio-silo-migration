# DEV-920: MinIO Feature Validation

## Objective

Validate selected MinIO single-node features in a local Docker Compose lab. This phase currently covers bucket versioning. Object Lock and lifecycle validation remain pending.

## Environment

- Platform: Windows with Docker Desktop
- Orchestration: Docker Compose
- MinIO image: `dappros/minio`
- MinIO release: `RELEASE.2025-09-07T16-13-09Z`
- Test bucket: `feature-validation`
- Test object: `version-test.txt`
- Test data: Synthetic text only

## Test 1: Object Versioning

### Procedure

1. Created the `feature-validation` bucket.
2. Enabled versioning on the bucket.
3. Created and uploaded an initial test object with `Version=1`.
4. Updated the same object with `Version=2` and uploaded it again.
5. Listed the object versions using `mc ls --versions`.
6. Retrieved the previous version using its exact version ID.

### Results

**Status: PASS**

Two versions of `version-test.txt` were observed.

| Version | Version ID | Result |
|---|---|---|
| Version 2 | `366dcac6-39f8-4617-98e6-511774f3cad3` | Newer version listed |
| Version 1 | `1a10fd23-e4da-4ff0-8d1d-2390f0fa40f8` | Previous content successfully retrieved |

The retrieved Version 1 content was:

```text
Product=DevMart
Task=DEV-920
TestData=VersioningValidation
Version=1
Description=Initial test object
```

This confirms that the earlier object version remained available after a subsequent upload and could be read using its version ID.

## Pending Tests

### Object Lock

- Verify bucket creation with Object Lock enabled.
- Test a retention policy using synthetic data.
- Confirm whether deletion is prevented during the retention period.
- Record any configuration or compatibility limitations.

### Lifecycle

- Configure a lifecycle expiration rule on a dedicated test bucket.
- Verify the rule configuration.
- Observe expiration behavior and record the result.
- Do not mark lifecycle validation as passed until expiration is actually observed or otherwise reliably verified.

## Evidence

Store supporting command output and screenshots under:

`docs/04-feature-validation/evidence/`

Evidence should include:

- Versioning enablement output
- Version listing with both version IDs
- Previous-version retrieval output
- Object Lock test results
- Lifecycle configuration and results

## Limitations

This is a local single-node feature-validation exercise. The results do not establish production readiness, distributed-mode behavior, or compatibility for every Silo feature.

## Current Status

- Versioning validation: **PASS**
- Object Lock validation: **Pending**
- Lifecycle validation: **Pending**
