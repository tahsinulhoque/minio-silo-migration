
$ErrorActionPreference = "Stop"

$ComposeFile = "compose.minio.yaml"
$ContainerName = "minio-silo-migration-minio-1"
$Bucket = "performance-benchmark"
$ObjectName = "benchmark-script-test.bin"
$EvidenceDir = "docs/06-performance-validation/evidence"
$LocalFile = Join-Path $EvidenceDir "benchmark-10MiB.bin"
$DownloadFile = Join-Path $env:TEMP "benchmark-script-download.bin"
$ResultsFile = Join-Path $EvidenceDir "benchmark-script-results.txt"

if (!(Test-Path $LocalFile -PathType Leaf)) {
    throw "Test file not found: $LocalFile"
}

$sizeBytes = (Get-Item $LocalFile).Length
$sizeMiB = $sizeBytes / 1MB

Write-Host "`n=== DEV-922 Local Benchmark ===" -ForegroundColor Cyan

# Confirm MinIO is reachable
docker compose -f $ComposeFile exec -T minio mc ls local/$Bucket/ | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "MinIO or benchmark bucket is unavailable."
}

# Copy test file into the MinIO container
docker cp $LocalFile "${ContainerName}:/tmp/$ObjectName"
if ($LASTEXITCODE -ne 0) {
    throw "Could not copy test file into container."
}

# Upload benchmark
$sw = [System.Diagnostics.Stopwatch]::StartNew()
docker compose -f $ComposeFile exec -T minio mc cp "/tmp/$ObjectName" "local/$Bucket/$ObjectName"
if ($LASTEXITCODE -ne 0) {
    throw "Upload failed."
}
$sw.Stop()

$uploadSeconds = $sw.Elapsed.TotalSeconds
$uploadMiBps = $sizeMiB / $uploadSeconds

# Download benchmark
$sw = [System.Diagnostics.Stopwatch]::StartNew()
docker compose -f $ComposeFile exec -T minio mc cp "local/$Bucket/$ObjectName" "/tmp/download-$ObjectName"
if ($LASTEXITCODE -ne 0) {
    throw "Download from MinIO failed."
}

docker cp "${ContainerName}:/tmp/download-$ObjectName" $DownloadFile
if ($LASTEXITCODE -ne 0) {
    throw "Could not copy downloaded file to Windows."
}
$sw.Stop()

$downloadSeconds = $sw.Elapsed.TotalSeconds
$downloadMiBps = $sizeMiB / $downloadSeconds

# Verify integrity
$originalHash = (Get-FileHash $LocalFile -Algorithm SHA256).Hash
$downloadHash = (Get-FileHash $DownloadFile -Algorithm SHA256).Hash
$match = $originalHash -eq $downloadHash

$results = @"
DEV-922 Local Benchmark
Date: $(Get-Date -Format o)
File size: $sizeBytes bytes ($([math]::Round($sizeMiB, 2)) MiB)

Upload duration: $([math]::Round($uploadSeconds, 3)) seconds
Upload end-to-end throughput: $([math]::Round($uploadMiBps, 2)) MiB/s

Download duration: $([math]::Round($downloadSeconds, 3)) seconds
Download end-to-end throughput: $([math]::Round($downloadMiBps, 2)) MiB/s

Original SHA-256: $originalHash
Downloaded SHA-256: $downloadHash
Checksum match: $match

Notes:
- Timings include Docker Compose command and Docker copy overhead.
- This is a local Docker-backed storage test, not an isolated disk benchmark.
- NFS comparison remains pending.
"@

$results | Set-Content -Encoding ascii $ResultsFile
$results
Write-Host "`nResults saved to $ResultsFile" -ForegroundColor Green

if (!$match) {
    throw "Checksum mismatch. Investigate before accepting this run."
}
