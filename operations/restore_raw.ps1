[CmdletBinding()]
[CmdletBinding()]
param(
    [string]$ProjectId = "aeroprecision-data-pipeline",
    [string]$DatasetId = "raw_manufacturing",
    [switch]$Execute,
    [switch]$ConfirmProductionReplace
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$dataDirectory = Join-Path (Join-Path $repoRoot "data") "raw"
$schemaDirectory = Join-Path $PSScriptRoot "schemas"

$productsCsv = Join-Path $dataDirectory "products_and_costs.csv"
$transactionsCsv = Join-Path $dataDirectory "quotation_transactions.csv"
$productsSchema = Join-Path $schemaDirectory "src_products.schema.json"
$transactionsSchema = Join-Path $schemaDirectory "src_transactions.schema.json"
$hashManifest = Join-Path $dataDirectory "SHA256SUMS.txt"

$requiredFiles = @(
    $productsCsv,
    $transactionsCsv,
    $productsSchema,
    $transactionsSchema,
    $hashManifest
)

function Get-NormalizedSha256 {
    param(
        [string]$Path
    )

    $text = [System.IO.File]::ReadAllText($Path)
    $normalizedText = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $bytes = $utf8.GetBytes($normalizedText)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()

    try {
        return (
            $sha256.ComputeHash($bytes) |
            ForEach-Object { $_.ToString("X2") }
        ) -join ""
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-NormalizedSha256Local {
    param([string]$Path)

    $text = [System.IO.File]::ReadAllText($Path)
    $normalizedText = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($normalizedText)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()

    try {
        return (($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
    }
    finally {
        $sha256.Dispose()
    }
}

$csvFiles = @(
    ".\data\raw\products_and_costs.csv",
    ".\data\raw\quotation_transactions.csv"
)

$csvFiles |
    ForEach-Object {
        "$(Get-NormalizedSha256Local -Path $_)  $(Split-Path $_ -Leaf)"
    } |
    Set-Content -Encoding ascii ".\data\raw\SHA256SUMS.txt"

Remove-Item Function:\Get-NormalizedSha256Local

Write-Host "Validating disaster-recovery files..." -ForegroundColor Cyan

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        throw "Required file not found: $file"
    }
}

# Validate that the schema files contain valid JSON.
Get-Content $productsSchema -Raw | ConvertFrom-Json | Out-Null
Get-Content $transactionsSchema -Raw | ConvertFrom-Json | Out-Null

# Validate SHA-256 checksums.
foreach ($line in Get-Content $hashManifest) {
    if ($line -notmatch "^(?<Hash>[0-9a-fA-F]{64})\s{2}(?<Name>.+)$") {
        throw "Invalid SHA256SUMS entry: $line"
    }

    $expectedHash = $Matches.Hash.ToUpper()
    $fileName = $Matches.Name
    $filePath = Join-Path $dataDirectory $fileName

    if (-not (Test-Path $filePath)) {
        throw "Checksum target not found: $filePath"
    }

    $actualHash = Get-NormalizedSha256 -Path $filePath

    if ($actualHash -ne $expectedHash) {
        throw "Checksum mismatch: $fileName"
    }
}

$productCount = @(Import-Csv $productsCsv).Count
$transactionCount = @(Import-Csv $transactionsCsv).Count

if ($productCount -ne 40) {
    throw "Expected 40 product rows, but found $productCount."
}

if ($transactionCount -ne 1000) {
    throw "Expected 1000 transaction rows, but found $transactionCount."
}

Write-Host "CSV checksums: PASS" -ForegroundColor Green
Write-Host "Product rows: $productCount" -ForegroundColor Green
Write-Host "Transaction rows: $transactionCount" -ForegroundColor Green
Write-Host "Schema JSON validation: PASS" -ForegroundColor Green

if (-not $Execute) {
    Write-Host ""
    Write-Host "Validation only. BigQuery was not changed." -ForegroundColor Yellow
    Write-Host "To perform recovery, run:"
    Write-Host ".\operations\restore_raw.ps1 -Execute"
    exit 0
}

if (-not (Get-Command bq -ErrorAction SilentlyContinue)) {
    throw "The bq command was not found. Install or initialize Google Cloud CLI."
}

function Invoke-RawTableLoad {
    param(
        [string]$TableName,
        [string]$CsvPath,
        [string]$SchemaPath
    )

    Write-Host "Loading $DatasetId.$TableName..." -ForegroundColor Cyan

    & bq `
        --quiet=true `
        --project_id=$ProjectId `
        load `
        --location=US `
        --replace=true `
        --source_format=CSV `
        --skip_leading_rows=1 `
        "$DatasetId.$TableName" `
        $CsvPath `
        $SchemaPath

    if ($LASTEXITCODE -ne 0) {
        throw "BigQuery load failed for $DatasetId.$TableName."
    }
    Write-Host "Refreshing expiration for $DatasetId.$TableName..." -ForegroundColor Cyan

& bq `
    --quiet=true `
    --project_id=$ProjectId `
    update `
    --expiration=5184000 `
    "$DatasetId.$TableName"

if ($LASTEXITCODE -ne 0) {
    throw "Failed to refresh expiration for $DatasetId.$TableName."
}
}

Invoke-RawTableLoad `
    -TableName "src_products" `
    -CsvPath $productsCsv `
    -SchemaPath $productsSchema

Invoke-RawTableLoad `
    -TableName "src_transactions" `
    -CsvPath $transactionsCsv `
    -SchemaPath $transactionsSchema

$verificationQuery = "SELECT 'src_products' AS table_name, COUNT(*) AS row_count FROM ``$ProjectId.$DatasetId.src_products`` UNION ALL SELECT 'src_transactions' AS table_name, COUNT(*) AS row_count FROM ``$ProjectId.$DatasetId.src_transactions`` ORDER BY table_name"

Write-Host "Verifying restored BigQuery row counts..." -ForegroundColor Cyan

& bq `
    --project_id=$ProjectId `
    query `
    --location=US `
    --use_legacy_sql=false `
    $verificationQuery

if ($LASTEXITCODE -ne 0) {
    throw "BigQuery verification query failed."
}

Write-Host "Raw recovery completed." -ForegroundColor Green