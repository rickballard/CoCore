[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Name,
  [string]$Title = "Pattern: $Name",
  [string[]]$Tags = @(),
  [string[]]$Jurisdictions = @("GLOBAL"),
  [string]$Maturity = "M2",
  [string]$Readiness = "R1"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot  = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$BaseDir   = Join-Path $RepoRoot ("coclusta\patterns\{0}" -f $Name)
$BriefPath = Join-Path $BaseDir "brief.md"
$SumPath   = Join-Path $BaseDir "congruence.json"
$ProvPath  = Join-Path $BaseDir "provenance.json"

if (Test-Path $BaseDir) { throw "Already exists: $BaseDir" }
New-Item -ItemType Directory -Path $BaseDir | Out-Null

$URN = "urn:cocivium:coclusta:patterns/{0}:v1" -f $Name
$TagsStr  = ($Tags | ForEach-Object { $_.Trim() }) -join ", "
$JurisStr = ($Jurisdictions | ForEach-Object { $_.Trim() }) -join ", "

# Build brief.md as an array of lines (no nested here-strings)
$brief = @()
$brief += "---"
$brief += "title: $Title"
$brief += "version: v1"
$brief += "authors: [CoCore Team]"
$brief += "urn: $URN"
$brief += "layer: coclusta"
$brief += "tags: [$TagsStr]"
$brief += "maturity: $Maturity"
$brief += "readiness: $Readiness"
$brief += "jurisdictions: [$JurisStr]"
$brief += ("congruence_ref: " + ($SumPath.Replace($RepoRoot+'\','').Replace('\','/')))
$brief += ("provenance_ref: " + ($ProvPath.Replace($RepoRoot+'\','').Replace('\','/')))
$brief += "warning_gate: safety/WARNING_GATE.yaml"
$brief += "summary: TODO one-paragraph summary"
$brief += "related_urns: []"
$brief += "---"
$brief += ""
$brief += "**What it is.** TODO  "
$brief += "**Why it matters.** TODO  "
$brief += "**Key constraints.** TODO"
$brief += ""
$brief += "---"
$brief += "<footer>"
$brief += "Congruence: TBC · Evidence: TBC · Build: receipt#TBC · Signed: CoCore/Signer"
$brief += "</footer>"
$brief -join "`n" | Set-Content -Path $BriefPath -Encoding UTF8

# Write congruence.json
$sum = @()
$sum += "{"
$sum += '  "id": "congruence.record.TBD",'
$sum += '  "version": "0.0.1",'
$sum += '  "rubric": ["transparency","coercion_avoidance","resilience","equity"],'
$sum += '  "weights": {"transparency":0.3,"coercion_avoidance":0.3,"resilience":0.25,"equity":0.15},'
$sum += '  "method": "weighted geometric mean with optional penalty",'
$sum += '  "calculator_ref": "tools/congruence/calc.py",'
$sum += '  "outputs": {"score": 0.0, "components": {"transparency":0.7,"coercion_avoidance":0.7,"resilience":0.7,"equity":0.7}, "uncertainty": 0.2},'
$sum += '  "penalty": 1.0,'
$sum += '  "provenance": ""'
$sum += "}"
$sum -join "`n" | Set-Content -Path $SumPath -Encoding UTF8

# Write provenance.json
$prov = @()
$prov += '{ "id":"prov.TBD", "source":"", "integrity":{"sha256":"","signed_by":""},'
$prov += '  "trust":{"merit_rank":0.0,"consensus":0.0,"recency_days":0,"conflicts_declared":false},'
$prov += '  "license":"", "notes":"" }'
$prov -join "`n" | Set-Content -Path $ProvPath -Encoding UTF8

Write-Host "Created pattern scaffold at $BaseDir" -ForegroundColor Green

