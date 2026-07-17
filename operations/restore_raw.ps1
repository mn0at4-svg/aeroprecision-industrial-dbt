[CmdletBinding()]
param(
    [string]$ProjectId = "aeroprecision-data-pipeline",
    [string]$DatasetId = "raw_manufacturing",
    [switch]$Execute,
    [switch]$ConfirmProductionReplace
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$dataDirectory = Join-Path (Join-Path $repoRoot "data") "raw"
$schemaDirectory = Join-Path $PSScriptRoot "schemas"

$productsCsv = Join-Path $dataDirectory "products_and_costs.csv"
$transactionsCsv = Join-Path $dataDirectory "quotation_transactions.csv"
$productsSchema = Join-Path $schemaDirectory "src_products.schema.json"
$transactionsSchema = Join-Path $schemaDirectory "src_transactions.schema.json"
$hashManifest = Join-Path $dataDirectory "SHA256SUMS.txt"

$tableExpirationSeconds = 5184000

$requiredFiles = @(
    $productsCsv,
    $transactionsCsv,
    $productsSchema,
    $transactionsSchema,
    $hashManifest
)

function Get-NormalizedSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $text = [System.IO.File]::ReadAllText($resolvedPath)

    # Normalize Windows CRLF and legacy CR line endings to Unix LF.
    $normalizedText = $text.Replace("`r`n", "`n").Replace("`r", "`n")

    # Calculate SHA-256 using UTF-8 without a byte-order mark.
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

function Invoke-RawTableLoad {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TableName,

        [Parameter(Mandatory)]
        [string]$CsvPath,

        [Parameter(Mandatory)]
        [string]$SchemaPath
    )

    Write-Host "Loading $DatasetId.$TableName..." -ForegroundColor Cyan

    $loadArguments = @(
        "--quiet=true"
        "--project_id=$ProjectId"
        "load"
        "--location=US"
        "--replace=true"
        "--source_format=CSV"
        "--skip_leading_rows=1"
        "$DatasetId.$TableName"
        $CsvPath
        $SchemaPath
    )

    & bq @loadArguments

    if ($LASTEXITCODE -ne 0) {
        throw "BigQuery load failed for $DatasetId.$TableName."
    }

    Write-Host "Refreshing expiration for $DatasetId.$TableName..." -ForegroundColor Cyan

    $expirationArguments = @(
        "--quiet=true"
        "--project_id=$ProjectId"
        "update"
        "--expiration=$tableExpirationSeconds"
        "$DatasetId.$TableName"
    )

    & bq @expirationArguments

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to refresh expiration for $DatasetId.$TableName."
    }
}

Write-Host "Validating disaster-recovery files..." -ForegroundColor Cyan

foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Required file not found: $file"
    }
}

# Validate that both schema files contain valid JSON.
Get-Content -LiteralPath $productsSchema -Raw |
    ConvertFrom-Json |
    Out-Null

Get-Content -LiteralPath $transactionsSchema -Raw |
    ConvertFrom-Json |
    Out-Null

# Validate the SHA-256 manifest.
$manifestLines = @(
    Get-Content -LiteralPath $hashManifest |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)

if ($manifestLines.Count -ne 2) {
    throw "SHA256SUMS.txt must contain exactly two entries."
}

$allowedFileNames = @(
    "products_and_costs.csv",
    "quotation_transactions.csv"
)

$validatedFileNames = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

foreach ($line in $manifestLines) {
    if ($line -notmatch "^(?<Hash>[0-9a-fA-F]{64})\s{2}(?<Name>[^\\/]+)$") {
        throw "Invalid SHA256SUMS entry: $line"
    }

    $expectedHash = $Matches.Hash.ToUpperInvariant()
    $fileName = $Matches.Name

    if ($fileName -notin $allowedFileNames) {
        throw "Unexpected checksum target: $fileName"
    }

    if (-not $validatedFileNames.Add($fileName)) {
        throw "Duplicate checksum entry: $fileName"
    }

    $filePath = Join-Path $dataDirectory $fileName
    $actualHash = Get-NormalizedSha256 -Path $filePath

    if ($actualHash -ne $expectedHash) {
        throw "Checksum mismatch: $fileName"
    }
}

foreach ($requiredName in $allowedFileNames) {
    if (-not $validatedFileNames.Contains($requiredName)) {
        throw "Missing checksum entry: $requiredName"
    }
}

$productCount = @(Import-Csv -LiteralPath $productsCsv).Count
$transactionCount = @(Import-Csv -LiteralPath $transactionsCsv).Count

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
    Write-Host "To restore production Raw tables, run:"
    Write-Host ".\operations\restore_raw.ps1 -Execute -ConfirmProductionReplace"
    exit 0
}

if (
    $DatasetId -eq "raw_manufacturing" -and
    -not $ConfirmProductionReplace
) {
    throw "Production Raw replacement is blocked. Re-run with -ConfirmProductionReplace only during an approved recovery."
}

if (-not (Get-Command bq -ErrorAction SilentlyContinue)) {
    throw "The bq command was not found. Install or initialize Google Cloud CLI."
}

Invoke-RawTableLoad `
    -TableName "src_products" `
    -CsvPath $productsCsv `
    -SchemaPath $productsSchema

Invoke-RawTableLoad `
    -TableName "src_transactions" `
    -CsvPath $transactionsCsv `
    -SchemaPath $transactionsSchema

$verificationQuery = "SELECT (SELECT COUNT(*) FROM ``$ProjectId.$DatasetId.src_products``) AS product_rows, (SELECT COUNT(*) FROM ``$ProjectId.$DatasetId.src_transactions``) AS transaction_rows"

Write-Host "Verifying restored BigQuery row counts..." -ForegroundColor Cyan

$queryArguments = @(
    "--quiet=true"
    "--project_id=$ProjectId"
    "query"
    "--location=US"
    "--use_legacy_sql=false"
    "--format=json"
    $verificationQuery
)

$verificationOutput = @(& bq @queryArguments)
$queryExitCode = $LASTEXITCODE

if ($queryExitCode -ne 0) {
    throw "BigQuery verification query failed."
}

try {
    $verificationJson = [string]::Join(
        [Environment]::NewLine,
        [string[]]$verificationOutput
    )

    $parsedVerification = ConvertFrom-Json -InputObject $verificationJson
    $verificationRows = @($parsedVerification)

    if ($verificationRows.Count -ne 1) {
        throw "Expected one verification row, but received $($verificationRows.Count)."
    }

    $verificationRow = $verificationRows[0]

    $restoredProductCount = [System.Convert]::ToInt32(
        $verificationRow.product_rows
    )

    $restoredTransactionCount = [System.Convert]::ToInt32(
        $verificationRow.transaction_rows
    )
}
catch {
    throw "Could not parse BigQuery verification output: $($_.Exception.Message)"
}

if ($restoredProductCount -ne 40) {
    throw "Expected 40 restored product rows, but found $restoredProductCount."
}

if ($restoredTransactionCount -ne 1000) {
    throw "Expected 1000 restored transaction rows, but found $restoredTransactionCount."
}

Write-Host "Restored src_products rows: $restoredProductCount" -ForegroundColor Green
Write-Host "Restored src_transactions rows: $restoredTransactionCount" -ForegroundColor Green
Write-Host "Raw recovery completed." -ForegroundColor Green