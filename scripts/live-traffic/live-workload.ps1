param(
    [int]$DurationSeconds = 60
)

$ErrorActionPreference = "Stop"

$Container = "minio-silo-migration-minio-1"
$Bucket = "feature-validation"
$ProxyAlias = "proxy"
$Endpoint = "http://migration-proxy:80"
$EvidenceDir = "docs/09-migrate-live-traffic-and-parity/evidence"
$CsvFile = Join-Path $EvidenceDir "live-traffic.csv"

New-Item -ItemType Directory -Force $EvidenceDir | Out-Null

# Configure proxy alias using credentials already injected into the container.
docker exec $Container sh -c 'mc alias set proxy http://migration-proxy:80 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"'
if ($LASTEXITCODE -ne 0) {
    throw "Proxy alias configuration failed."
}

$results = [System.Collections.Generic.List[object]]::new()
$deadline = (Get-Date).AddSeconds($DurationSeconds)
$counter = 0

Write-Host "Starting live workload through Nginx proxy..." -ForegroundColor Cyan

while ((Get-Date) -lt $deadline) {
    $counter++
    $object = "live-traffic-$counter.txt"
    $localFile = Join-Path $env:TEMP $object
    $containerFile = "/tmp/$object"

    "DEV-925 live workload request $counter at $((Get-Date).ToString('o'))" |
        Set-Content -Path $localFile -NoNewline

    docker cp $localFile "${Container}:$containerFile" | Out-Null

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    docker exec $Container mc cp $containerFile "$ProxyAlias/$Bucket/$object" 2>&1 | Out-Null
    $exitCode = $LASTEXITCODE
    $timer.Stop()

    $results.Add([PSCustomObject]@{
        Timestamp = (Get-Date).ToString("o")
        Request = "PUT"
        Object = $object
        Status = if ($exitCode -eq 0) { "SUCCESS" } else { "FAILED" }
        LatencyMs = [math]::Round($timer.Elapsed.TotalMilliseconds, 2)
        ExitCode = $exitCode
    })

    Remove-Item $localFile -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 250
}

$results | Export-Csv -Path $CsvFile -NoTypeInformation -Encoding UTF8

$failed = @($results | Where-Object Status -eq "FAILED").Count
$avg = [math]::Round(($results | Measure-Object LatencyMs -Average).Average, 2)
$max = ($results | Measure-Object LatencyMs -Maximum).Maximum

Write-Host "`nRequests: $($results.Count)"
Write-Host "Failed: $failed"
Write-Host "Average latency: $avg ms"
Write-Host "Maximum latency: $max ms"
Write-Host "Evidence: $CsvFile"
