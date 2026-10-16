```powershell
$ErrorActionPreference = "Stop"

$ComposeFile = "compose.minio.yaml"
$Bucket = "replication-smoke"
$Object = "replication-test.txt"
$ContainerFile = "/tmp/replication-test.txt"
$LocalFile = Join-Path $env:TEMP $Object

Write-Host "`n=== DEV-919 Replication Smoke Test ===" -ForegroundColor Cyan

# Step 1: Create test file on Windows
$content = "DEV-919 automatic replication test"
[System.IO.File]::WriteAllText($LocalFile, $content)

Write-Host "[1/5] Test file created."

# Step 2: Copy file into the MinIO container
docker cp $LocalFile minio-silo-migration-minio-1:$ContainerFile
if ($LASTEXITCODE -ne 0) {
    throw "Failed to copy test file into the MinIO container."
}

Write-Host "[2/5] Test file copied into source container."

# Step 3: Upload to source bucket
docker compose -f $ComposeFile exec -T minio mc cp `
    $ContainerFile "local/$Bucket/$Object"

if ($LASTEXITCODE -ne 0) {
    throw "Source upload failed."
}

Write-Host "[3/5] Source upload command succeeded."

# Step 4: Verify source object
docker compose -f $ComposeFile exec -T minio mc stat `
    "local/$Bucket/$Object"

if ($LASTEXITCODE -ne 0) {
    throw "Source object verification failed."
}

Write-Host "[4/5] Source object verified."

# Step 5: Check target replication
Start-Sleep -Seconds 5

docker compose -f $ComposeFile exec -T minio mc stat `
    "target/$Bucket/$Object"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nPASS: Target object exists. Check checksum before final acceptance." -ForegroundColor Green
}
else {
    Write-Host "`nNOT VERIFIED: Target object is missing or unavailable. Replication needs troubleshooting." -ForegroundColor Yellow
}
```