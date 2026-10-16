
$ErrorActionPreference = "Stop"

$ComposeFile = "compose.minio.yaml"
$SourceAlias = "local"
$TargetAlias = "silo"
$Bucket = "silo-replication-smoke"
$Object = "silo-test.txt"
$ContainerFile = "/tmp/silo-test.txt"
$LocalFile = Join-Path $env:TEMP $Object

Write-Host "`n=== DEV-919: MinIO to Silo Test ===" -ForegroundColor Cyan

# 1. Create test file on Windows
$content = "DEV-919 MinIO-to-Silo test $(Get-Date -Format o)"
[System.IO.File]::WriteAllText($LocalFile, $content)

# 2. Copy file into source container
docker cp $LocalFile "minio-silo-migration-minio-1:$ContainerFile"
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: Could not copy test file into source container."
}

# 3. Upload to MinIO source bucket
docker compose -f $ComposeFile exec -T minio mc cp `
    $ContainerFile "$SourceAlias/$Bucket/$Object"

if ($LASTEXITCODE -ne 0) {
    throw "FAIL: Source upload failed."
}

# 4. Verify source object
docker compose -f $ComposeFile exec -T minio mc stat `
    "$SourceAlias/$Bucket/$Object"

if ($LASTEXITCODE -ne 0) {
    throw "FAIL: Source object could not be verified."
}

Write-Host "`nSource upload verified. Waiting 10 seconds for replication..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 5. Verify target object in Silo
docker compose -f $ComposeFile exec -T minio mc stat `
    "$TargetAlias/$Bucket/$Object"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nTARGET OBJECT FOUND: replication may be working." -ForegroundColor Green
    Write-Host "Compare source and target checksums before declaring PASS."
}
else {
    Write-Host "`nNOT VERIFIED: object did not appear in Silo." -ForegroundColor Yellow
    Write-Host "Check replication status and server compatibility."
}
