# DO — Fetch open references listed in references/catalog.yaml
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Resolve repo root: .../tools/ps -> repo root
$RepoRoot  = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$Catalog   = Join-Path $RepoRoot "references\catalog.yaml"
$OutRoot   = Join-Path $RepoRoot "references\mirrors"
$Checksums = Join-Path $OutRoot "checksums.json"

if (-not (Test-Path $Catalog)) { throw "Catalog not found: $Catalog" }
if (-not (Test-Path $OutRoot)) { New-Item -ItemType Directory -Path $OutRoot | Out-Null }

function Parse-Catalog {
  param([string]$Path)
  $text = Get-Content $Path -Raw
  # Try ConvertFrom-Yaml first (if available)
  if (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
    $yaml = $text | ConvertFrom-Yaml
    if ($null -eq $yaml -or $null -eq $yaml.items) { throw "YAML missing 'items' node." }
    return ,$yaml.items
  }
  # YAML-lite fallback: find the items block and parse "- id:" entries + simple "key: value" lines
  $lines = $text -split "`n"
  $start = ($lines | Select-String -SimpleMatch 'items:' | Select-Object -First 1).LineNumber
  if (-not $start) { throw "'items:' section not found" }
  $items = @()
  $current = $null
  for ($i = $start; $i -lt $lines.Count; $i++) {
    $ln = $lines[$i]
    if ($ln -match '^\s*-\s*id:\s*(.+)\s*$') {
      if ($current) { $items += [pscustomobject]$current }
      $current = @{ id = ($Matches[1].Trim().Trim("'`"")) }
      continue
    }
    if ($ln -match '^\s+(\w+):\s*(.+?)\s*$' -and $null -ne $current) {
      $k = $Matches[1]; $v = $Matches[2].Trim().Trim("'`"")
      $current[$k] = $v
      continue
    }
    if ($ln -match '^\S') { break } # left the items block
  }
  if ($current) { $items += [pscustomobject]$current }
  if (-not $items) { throw "No entries parsed in catalog 'items:'" }
  return ,$items
}

$items = Parse-Catalog -Path $Catalog

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
    Invoke-WebRequest -Uri $url -OutFile $Target -UseBasicParsing -TimeoutSec 300
    $sha = (Get-FileHash -Algorithm SHA256 $Target).Hash.ToLower()
    $rel = $Target.Replace($RepoRoot+'\','')
    $dl += [pscustomobject]@{ id=$id; path=$rel; sha256=$sha; ts=(Get-Date).ToString('s') }
  } catch {
    Write-Warning "Failed: $id from $url — $($_.Exception.Message)"
  }
}

@{ items = $dl } | ConvertTo-Json -Depth 5 | Set-Content -Path $Checksums -Encoding UTF8
Write-Host "`nMirrored $($dl.Count) open references to $OutRoot" -ForegroundColor Green
