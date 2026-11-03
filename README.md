# MinIO to Silo Migration

A Docker-based project for migrating object storage from MinIO to Silo using replication, Nginx reverse proxying, data verification, and controlled traffic cutover.

## 1. Project Overview

This project implements a local object storage migration environment where an existing MinIO instance is migrated to Silo while maintaining access to stored objects.

The migration uses server-side bucket replication to synchronize objects between the source MinIO instance and Silo. An Nginx reverse proxy provides a single endpoint through which client requests can be routed to the storage backend.

The project also includes a separate MinIO target instance for migration testing, Docker Compose configurations, and scripts for generating live workload and collecting verification evidence.

The main objective is to evaluate the migration process, replication behavior, data consistency, traffic switching, and rollback readiness in a controlled environment.

**Project type:** Object Storage Migration  
**Source storage:** MinIO  
**Target storage:** Silo  
**Infrastructure:** Docker Compose  
**Proxy:** Nginx  
**Environment:** Local development and testing

## 2. Project Objectives

- Set up MinIO and Silo as separate object storage services.
- Configure server-side replication from MinIO to Silo.
- Maintain object synchronization during migration.
- Verify object availability and data consistency.
- Test versioning, object updates, and delete operations.
- Route client requests through an Nginx reverse proxy.
- Generate continuous workload and collect request-level evidence.
- Configure reverse replication for rollback preparation.
- Test traffic cutover and rollback procedures.
- Document migration procedures, verification results, and limitations.

## 3. Architecture

The project uses separate Docker containers for the source storage, target storage, optional MinIO target, and Nginx proxy.

### Main Components

| Component | Purpose | Host Port |
|---|---|---|
| Source MinIO | Original object storage service | 9000 |
| Source MinIO Console | Source management interface | 9001 |
| Silo | Target object storage service | 9100 |
| Silo Console | Target management interface | 9101 |
| Additional MinIO Target | Separate replication/testing target | 9200 |
| Nginx Proxy | Client request routing | 9300 |

All published service ports are bound to `127.0.0.1`.

### Architecture Flow

```text
                  Client / Workload
                         |
                         |
                  Nginx Reverse Proxy
                     Port 9300
                         |
                         |
                Configured Storage Backend
                         |
              +----------+----------+
              |                     |
              |                     |
         Source MinIO              Silo
          Port 9000              Port 9100
              |                     |
              +---- Replication ----+
                     MinIO to Silo

              Reverse replication
                     Silo to MinIO
                  (configured for
                  migration testing)
```

The proxy backend is controlled by the Nginx configuration. During migration, this configuration is changed to direct traffic to the selected storage service.

## 4. Technology Stack

| Technology | Usage |
|---|---|
| MinIO | Source object storage |
| Silo | Target object storage |
| Docker | Container runtime |
| Docker Compose | Service orchestration |
| Nginx | Reverse proxy and traffic routing |
| MinIO Client (`mc`) | Bucket management, replication and object verification |
| PowerShell | Workload automation and operational commands |
| Python | Object verification using the MinIO SDK |
| Git | Version control and project documentation |

## 5. Repository Structure

```text
minio-silo-migration/
│
├── docs/
│   └── 09-migrate-live-traffic-and-parity/
│       ├── README.md
│       └── evidence/
│           ├── live-traffic.csv
│           ├── silo-stop-recovery.txt
│           ├── network-disconnect-recovery.txt
│           └── source-restart-recovery.txt
│
├── nginx/
│   └── proxy.conf
│
├── scripts/
│   ├── live-traffic/
│   │   └── live-workload.ps1
│   │
│   └── verification/
│       └── verify-file.ps1
│
├── .env.example
├── .gitignore
│
├── compose.minio.yaml
├── compose.silo.yaml
├── compose.minio-target.yaml
├── compose.proxy.yaml
│
├── migration-test.txt
├── test-object-01.txt
├── version-test.txt
│
└── README.md
```

The structure above highlights the main project components and available files. Additional migration documentation and evidence are maintained under `docs/`.

## 6. Prerequisites

Install the following tools before starting the environment:

- Docker Desktop
- Docker Compose
- MinIO Client (`mc`)
- PowerShell
- Git

For Python-based verification, install Python and the MinIO SDK:

```powershell
pip install minio
```

## 7. Environment Configuration

The project uses environment variables to configure the storage services.

Create a local `.env` file from the example:

```powershell
Copy-Item .env.example .env
```

Configure the required credentials in `.env`:

```env
MINIO_ROOT_USER=your_admin_username
MINIO_ROOT_PASSWORD=your_strong_password
```

Use strong credentials for your environment.

The `.env` file is intended for local configuration and should not be committed to Git.

## 8. Start the Environment

### Step 1: Create the Docker Network

The Compose services use an external Docker network named `migration-net`.

Create it before starting the services:

```powershell
docker network create migration-net
```

If the network already exists, it does not need to be created again.

### Step 2: Start Source MinIO

```powershell
docker compose -f compose.minio.yaml up -d
```

Source MinIO services:

- API: `http://127.0.0.1:9000`
- Console: `http://127.0.0.1:9001`

### Step 3: Start Silo

```powershell
docker compose -f compose.silo.yaml up -d
```

Silo services:

- API: `http://127.0.0.1:9100`
- Console: `http://127.0.0.1:9101`

### Step 4: Start the Nginx Proxy

```powershell
docker compose -f compose.proxy.yaml up -d
```

Proxy endpoint:

```text
http://127.0.0.1:9300
```

### Step 5: Start the Additional MinIO Target (Optional)

The repository also includes a separate MinIO target configuration for additional migration and replication testing.

```powershell
docker compose -f compose.minio-target.yaml up -d
```

Its API and console are published on ports 9200 and 9201 respectively.

## 9. Storage and Replication Configuration

The project uses separate storage volumes for the source MinIO and Silo services.

This allows each storage service to maintain its own data independently.

The primary migration bucket used in the verification work is:

```text
feature-validation
```

### Source to Silo Replication

The initial replication direction is:

```text
Source MinIO → Silo
```

The replication configuration is managed through the MinIO Client.

Example command for inspecting the source replication configuration:

```bash
mc replicate ls local/feature-validation
```

The configured replication rule identifies Silo as the remote destination.

### Reverse Replication

For rollback preparation, a reverse replication rule was configured:

```text
Silo → Source MinIO
```

This rule allows changes made on Silo to be replicated back to the original MinIO service.

The reverse replication configuration can be inspected with:

```bash
mc replicate ls silo/feature-validation
```

Both replication directions are configured separately. Their actual synchronization behavior must be verified through object-level tests rather than relying only on the presence of replication rules.

## 10. Nginx Reverse Proxy

Nginx provides a single endpoint for client requests.

The proxy configuration is maintained in:

```text
nginx/proxy.conf
```

The Docker Compose configuration mounts this file into the Nginx container.

The proxy currently uses an upstream storage backend.

Example configuration:

```nginx
upstream storage_backend {
    server 172.24.0.4:9000;
}

server {
    listen 80;
    client_max_body_size 0;

    location / {
        proxy_pass http://storage_backend;
        proxy_http_version 1.1;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_buffering off;
        proxy_request_buffering off;
    }
}
```

The backend address must match the actual Docker network address of the selected storage service.

The IP address shown above is from the current local configuration and may change if the Docker network or containers are recreated.

### Validate Nginx Configuration

```powershell
docker exec migration-proxy nginx -t
```

### Reload Nginx

```powershell
docker exec migration-proxy nginx -s reload
```

The proxy backend can be changed during migration to route requests to the selected storage service.

## 11. Live Workload Generation

The project includes a PowerShell workload script:

```text
scripts/live-traffic/live-workload.ps1
```

The script generates object upload requests through the Nginx proxy.

It performs the following operations:

1. Configures the proxy alias using credentials available inside the MinIO container.
2. Generates unique object names.
3. Creates local test files.
4. Uploads the files through the proxy.
5. Measures request execution time.
6. Records request timestamps, operation types, object names, status, latency, and exit codes.
7. Exports the results to a CSV file.

Run the workload from PowerShell:

```powershell
.\scripts\live-traffic\live-workload.ps1 -DurationSeconds 60
```

The duration can be changed as required.

The generated evidence is stored at:

```text
docs/09-migrate-live-traffic-and-parity/evidence/live-traffic.csv
```

The current workload script generates PUT requests. It should not be considered a complete mixed read/write workload generator.

## 12. Data Verification

Data consistency is an important part of the migration process.

The project uses MinIO Client commands and Python-based verification to compare source and target objects.

### Check Bucket Versioning

```bash
mc version info local/feature-validation
mc version info silo/feature-validation
```

### Check Object Information

```bash
mc stat local/feature-validation/object-name.txt
mc stat silo/feature-validation/object-name.txt
```

### Compare Object Listings

```bash
mc ls --recursive local/feature-validation
mc ls --recursive silo/feature-validation
```

### Compare Current Objects

```bash
mc diff local/feature-validation silo/feature-validation
```

### Verify Object Content

The verification process uses object checksums to compare downloaded content from the source and target storage services.

The Python MinIO SDK is also used for object reads and SHA-256 checksum comparisons.

These checks help identify:

- Missing objects
- Additional objects
- Content mismatches
- Differences in object sizes
- Differences in object metadata

Historical version parity, delete-marker parity, retention, and encryption settings require separate verification and should not be inferred from a current-object comparison alone.

## 13. Implemented Work and Verification Results

The following work has been performed and tested during the project.

### Infrastructure

- Created separate Docker Compose configurations for Source MinIO and Silo.
- Created a separate MinIO target configuration.
- Configured persistent Docker volumes.
- Connected the services through the shared `migration-net` network.
- Pinned container images by digest.
- Bound published service ports to localhost.

### Replication

- Configured Source MinIO to Silo replication.
- Enabled bucket versioning on both migration buckets.
- Configured reverse replication from Silo to Source MinIO.
- Inspected replication configurations using `mc replicate ls`.
- Tested object replication and replication recovery scenarios.

### Data Verification

During the Sub-task 9 verification work:

- Compared current object listings between Source MinIO and Silo.
- Verified 266 current objects on each side.
- Ran a full current-object SHA-256 comparison.
- The recorded comparison reported no missing objects, extra objects, or checksum mismatches.
- Performed additional sample reads from both storage services.
- Compared object metadata and tested versioned object operations.
- Tested detection of an intentional object difference.

The historical version, retention, and legal-hold checks have limitations and are documented in the corresponding verification write-up.

### Replication Recovery

The project includes evidence from the following recovery tests:

- Silo stop and recovery.
- Network disconnection and recovery.
- Source restart testing.
- Replication queue and error-status observations.

The recorded workload and recovery results are available under:

```text
docs/09-migrate-live-traffic-and-parity/evidence/
```

These results represent the tests actually performed and do not establish that every migration acceptance criterion has passed.

### Traffic Cutover

The DEV-926 work has started.

The following actions have been performed:

- Inspected the existing proxy configuration.
- Configured and verified a reverse replication rule from Silo to Source MinIO.
- Tested GET routing to Silo.
- Successfully read an existing replicated object through the proxy.
- Changed the proxy configuration to direct all traffic to Silo.
- Successfully validated and reloaded the Nginx configuration.

The subsequent write-cutover test has not yet been verified successfully. The test object was not found in either storage service during the recorded verification attempt.

Rollback, final cutover, source decommissioning, and final standalone Silo verification remain pending.

## 14. Evidence and Documentation

Migration-specific documentation and evidence are maintained under the `docs/` directory.

The Sub-task 9 write-up is available at:

```text
docs/09-migrate-live-traffic-and-parity/README.md
```

Its evidence directory contains workload and recovery records.

The Sub-task 10 write-up and final migration summary are intended to document:

- Cutover and rollback procedures.
- Request logs and timing measurements.
- Replication verification.
- Data consistency results.
- Source decommissioning.
- Final Silo-only operation.
- Known limitations and open issues.

These documents should reflect the steps actually executed and the results observed.

## 15. Security Considerations

- Do not commit `.env` files.
- Do not include storage credentials in scripts, documentation, or Git commits.
- Use strong credentials for all storage services.
- Keep administrative console ports bound to localhost in this local testing environment.
- Avoid exposing MinIO or Silo administrative interfaces publicly.
- Rotate credentials if they have been exposed.
- Review proxy routing and storage permissions before performing production migration.

The current setup is intended for local testing, not as a production deployment configuration.

## 16. Current Project Status

The project is being developed and tested through multiple migration stages.

| Area | Current Status |
|---|---|
| Docker environment | Implemented |
| Source MinIO setup | Implemented |
| Silo setup | Implemented |
| Nginx proxy | Implemented |
| Source-to-Silo replication | Configured and tested |
| Bucket versioning | Enabled and verified |
| Current-object checksum comparison | Passed in recorded test |
| Replication recovery testing | Performed |
| Reverse replication | Configured |
| Read traffic cutover test | Tested |
| Write traffic cutover | Not yet verified |
| Rollback testing | Pending |
| Final Silo cutover | Pending |
| Source decommissioning | Pending |
| Final standalone Silo verification | Pending |

## 17. Limitations and Open Issues

The project is a controlled local migration test environment. The following limitations should be considered:

- The proxy configuration currently uses a Docker network IP address, which may change when containers or networks are recreated.
- The existing live workload script generates PUT requests rather than a complete mixed workload.
- A successful reverse replication rule configuration does not by itself prove that every object operation is being replicated correctly.
- Full historical version and delete-marker parity requires additional verification.
- Retention and legal-hold parity have not been fully verified because the tested bucket configuration does not support Object Lock.
- The write cutover test has not yet been confirmed successful.
- Rollback and final source decommissioning have not yet been completed.
- The zero-downtime acceptance criteria have not yet been fully demonstrated.

## 18. Conclusion

This project provides a local environment for testing the migration of object storage from MinIO to Silo.

It includes Docker-based infrastructure, server-side replication, reverse replication configuration, Nginx proxy routing, live workload generation, and data verification procedures.

The completed verification work provides evidence of current-object consistency and selected replication recovery scenarios. The migration cutover and rollback stages are still in progress.

The final migration outcome will depend on successful write cutover, rollback, final Silo operation without the source MinIO service, and the corresponding verification evidence.

## 19. Auhor 
Md.Tahsinul Hoque Siddiki

## 20.Repository
GitHub:
https://github.com/tahsinulhoque/minio-silo-migration

