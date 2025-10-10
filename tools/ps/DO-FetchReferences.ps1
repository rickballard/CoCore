# DO — Fetch open references listed in references/catalog.yaml (robust YAML)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Resolve repo root: .../tools/ps -> repo root
$RepoRoot  = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$Catalog   = Join-Path $RepoRoot "references\catalog.yaml"
$OutRoot   = Join-Path $RepoRoot "references\mirrors"
$Checksums = Join-Path $OutRoot "checksums.json"

if (-not (Test-Path $Catalog)) { throw "Catalog not found: $Catalog" }
if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
  throw "ConvertFrom-Yaml not found. PowerShell 7.2+ required (Microsoft.PowerShell.Utility module)."
}

# Parse YAML properly
$yaml = Get-Content $Catalog -Raw | ConvertFrom-Yaml
$items = @()
if ($null -ne $yaml -and $null -ne $yaml.items) { $items = $yaml.items } else { throw "YAML catalog missing 'items'." }

# Ensure mirrors directory
if (-not (Test-Path $OutRoot)) { New-Item -ItemType Directory -Path $OutRoot | Out-Null }

$dl = @()
foreach ($it in $items) {
  $id = $it.id
  $url = $it.url
  $acc = $it.access
  $mir = $it.mirror
  if ([string]::IsNullOrWhiteSpace($id)) { continue }
  if ($acc -ne 'open') { continue }
  if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($mir)) { continue }

  $Target = Join-Path $OutRoot ($mir -replace '/','\')
  $Dir    = Split-Path $Target -Parent
  if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir | Out-Null }

  try {
    Write-Host "Downloading $id -> $Target"
    Invoke-WebRequest -Uri $url -OutFile $Target -UseBasicParsing -TimeoutSec 240
    $sha = (Get-FileHash -Algorithm SHA256 $Target).Hash.ToLower()
    $rel = $Target.Replace($RepoRoot+'\','')
    $dl += [pscustomobject]@{ id=$id; path=$rel; sha256=$sha; ts=(Get-Date).ToString('s') }
  } catch {
    Write-Warning "Failed: $id from $url — $($_.Exception.Message)"
  }
}

# Write checksum receipt
@{ items = $dl } | ConvertTo-Json -Depth 5 | Set-Content -Path $Checksums -Encoding UTF8
Write-Host "`nMirrored $($dl.Count) open references to $OutRoot" -ForegroundColor Green
