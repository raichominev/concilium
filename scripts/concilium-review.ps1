# concilium-review.ps1 — adversarial cross-model review via the OpenAI codex CLI
# (ChatGPT-subscription auth; no API key). See SKILL.md for the method and
# references/pitfalls.md for why each rule exists.
#
# The review contract lives in references/contract.md (single source of truth shared with the
# bash wrapper) — edit it there, not here.
#
# Modes:
#   -Claim "<text>"        : falsification-probe review of a claim (codex exec, read-only)
#   -Diff                  : review the working-tree diff of -RepoDir (codex review --uncommitted)
#   -Base <branch>         : with -Diff, review against a base branch instead
#   -Mechanical            : mechanical tier — verify a known claim with one probe
#   -ProjectRules <file>   : optional project ground-rules file appended to the contract
#   -PriorRounds <file>    : loop mode — prior rounds' probes + the objection; reviewer must take
#                            a NEW evidence path (see SKILL.md "The concilium loop")
#
# Defaults are models current at authoring time (2026-07) — check `codex debug models` and
# override with -Model, or edit for your installation.
#
# Prompt goes via STDIN (npm codex shims word-split multi-line args). Do NOT set
# $ErrorActionPreference='Stop' (codex writes progress to stderr; PS5.1 would abort).
# Resume a session ONLY with the full re-pin (see SKILL.md):
#   codex exec resume -m <model> -c sandbox_mode="read-only" -c model_reasoning_effort=<tier> <id> -

param(
  [string]$Claim,
  [switch]$Diff,
  [string]$Base,
  [switch]$Mechanical,
  [string]$ProjectRules,
  [string]$PriorRounds,
  [string]$Model  = "gpt-5.6-sol",
  [string]$Effort = "high",
  [string]$RepoDir = ""
)

if ($Mechanical) {
  if (-not $PSBoundParameters.ContainsKey('Model'))  { $Model  = "gpt-5.5" }
  if (-not $PSBoundParameters.ContainsKey('Effort')) { $Effort = "medium" }
}

$ErrorActionPreference = "Continue"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $RepoDir) {
  $RepoDir = (& git rev-parse --show-toplevel 2>$null)
  if (-not $RepoDir) { $RepoDir = (Get-Location).Path }
}

$ContractPath = Join-Path $PSScriptRoot "..\references\contract.md"
if (-not (Test-Path $ContractPath)) {
  Write-Error "Contract file not found: $ContractPath"
  exit 3
}
$Contract = Get-Content -Raw -Encoding UTF8 $ContractPath

if ($ProjectRules -and (Test-Path $ProjectRules)) {
  $Contract += "`n`n--- PROJECT GROUND RULES (binding) ---`n" + (Get-Content -Raw $ProjectRules)
}

# Loop mode: prior rounds' probes + the orchestrator's objection, so this round takes a NEW path.
if ($PriorRounds -and (Test-Path $PriorRounds)) {
  $Contract += "`n`n--- PRIOR ROUNDS (do NOT repeat these probes; take a new evidence path; address the objection) ---`n" + (Get-Content -Raw $PriorRounds)
}

if (-not $Diff -and [string]::IsNullOrWhiteSpace($Claim)) {
  Write-Error "Provide -Claim `"<text>`" or -Diff. See the header for usage."
  exit 2
}

# Provenance stamp: the model does not reliably know its own id, so the wrapper injects it.
$ContractFull = $Contract + "`n`nRuntime provenance (use in PHASE-LOG): model=$Model, effort=$Effort."

if ($Diff) {
  Push-Location $RepoDir
  try {
    $codexArgs = @("review", "-c", "model=$Model", "-c", "model_reasoning_effort=$Effort")
    if ($Base) { $codexArgs += @("--base", $Base) } else { $codexArgs += "--uncommitted" }
    $codexArgs += "-"   # contract via stdin
    Write-Host ">> codex $($codexArgs -join ' ')  (model=$Model, repo=$RepoDir)" -ForegroundColor DarkGray
    $ContractFull | & codex @codexArgs
  } finally { Pop-Location }
}
else {
  $prompt = "$ContractFull`n`n--- CLAIM UNDER REVIEW ---`n$Claim"
  $codexArgs = @("exec", "-m", $Model, "-s", "read-only", "--skip-git-repo-check",
                 "-c", "model_reasoning_effort=$Effort")
  Write-Host ">> codex exec -m $Model -s read-only (claim via stdin)" -ForegroundColor DarkGray
  Push-Location $RepoDir
  try { $prompt | & codex @codexArgs } finally { Pop-Location }
}
