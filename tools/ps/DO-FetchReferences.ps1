# DO — Fetch open references listed in references/catalog.yaml
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot  = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Catalog   = Join-Path $RepoRoot "references\catalog.yaml"
$OutRoot   = Join-Path $RepoRoot "references\mirrors"
$Checksums = Join-Path $OutRoot "checksums.json"

if (-not (Test-Path $Catalog)) { throw "Catalog not found: $Catalog" }
if (-not (Test-Path $OutRoot)) { New-Item -ItemType Directory -Path $OutRoot | Out-Null }

# naive YAML block splitter (no external modules)
$content = Get-Content $Catalog -Raw
$blocks  = $content -split "`n\s*-\s*id:\s*"
$items   = @()
foreach ($b in $blocks) {
  if (-not $b.Trim()) { continue }
  $lines = $b -split "`n"
  $id    = $lines[0].Trim()
  $obj   = @{ id = $id }
  foreach ($ln in $lines[1..($lines.Length-1)]) {
    if ($ln -match '^\s+(\w+):\s*(.+)$') { $obj[$Matches[1]] = $Matches[2].Trim() }
  }
  $items += [pscustomobject]$obj
}

$dl = @()
foreach ($it in $items) {
  if (-not $it.access -or -not $it.url) { continue }
  if ($it.access -ne 'open') { continue }
  if (-not $it.mirror -or $it.mirror -eq 'None') { continue }

  $Target = Join-Path $OutRoot ($it.mirror -replace '/','\')
  $Dir    = Split-Path $Target -Parent
  if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir | Out-Null }

  try {
    Write-Host "Downloading $($it.id) -> $Target"
    Invoke-WebRequest -Uri $it.url -OutFile $Target -UseBasicParsing -TimeoutSec 180
    $sha = (Get-FileHash -Algorithm SHA256 $Target).Hash.ToLower()
    $dl += @{id=$it.id; path=($Target.Replace($RepoRoot+'\','')); sha256=$sha; ts=(Get-Date).ToString('s')}
  } catch {
    Write-Warning "Failed: $($it.id) from $($it.url) — $($_.Exception.Message)"
  }
}

@{ items = $dl } | ConvertTo-Json -Depth 5 | Set-Content -Path $Checksums -Encoding UTF8
Write-Host "`nMirrored $($dl.Count) open references to $OutRoot" -ForegroundColor Green
