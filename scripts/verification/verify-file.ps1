param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

if (!(Test-Path $Path -PathType Leaf)) {
    Write-Error "File not found: $Path"
    exit 1
}

$file = Get-Item $Path
$hash = Get-FileHash $Path -Algorithm SHA256

[PSCustomObject]@{
    FileName = $file.Name
    SizeBytes = $file.Length
    SHA256 = $hash.Hash
} | Format-List
