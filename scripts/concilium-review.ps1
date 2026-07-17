# concilium-review.ps1 — adversarial cross-model review via the OpenAI codex CLI
# (ChatGPT-subscription auth; no API key). Generic — see the skill's SKILL.md for the method
# and references/pitfalls.md for why each rule exists.
#
# Modes:
#   -Claim "<text>"        : falsification-probe review of a claim (codex exec, read-only)
#   -Diff                  : review the working-tree diff of -RepoDir (codex review --uncommitted)
#   -Base <branch>         : with -Diff, review against a base branch instead
#   -Mechanical            : mechanical tier — verify a known claim with one probe
#   -ProjectRules <file>   : optional project ground-rules file appended to the contract
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

$Contract = @'
You are the cross-model REVIEWER: an independent second opinion from a different model lineage.
Review adversarially — do not defer to the researcher/author. Binding contract:
1. Never build on a load-bearing unverified claim without verifying it first.
2. Run >=1 falsification probe. Review-by-reading is NOT review.
3. Attempt >=1 alternative causal explanation of the headline claim.
4. Prefer independent re-derivation (your own check, a different evidence path) over re-running
   the author's script.
5. Credit refutations, not confirmations; claims travel WITH their evidence.
6. Schema caution: two columns with similar or identical names (same name across DIFFERENT
   tables/models, or two differently-named id-ish columns on the SAME model) are NOT guaranteed
   to share an ID space or semantics. Before joining on any "id"-style column, check the
   docstrings/comments AND sample real values on both sides. State the SCOPE of every count.
7. Encoding: any child process you spawn must force UTF-8 output ([Console]::OutputEncoding,
   chcp 65001, PYTHONIOENCODING; on POSIX a UTF-8 LANG/LC_ALL) — non-ASCII data crashes default console codepages mid-probe.

Output exactly these five blocks:
  PROBE:       the falsification probe you ran + its result (include the actual query/commands)
  ALT:         one alternative causal explanation you considered
  CAVEAT:      what this probe did NOT verify — coverage gaps, proxy/fallback methodology, scope
               limits, drift from the claim's original protocol. "none" ONLY if the probe
               exercised the claim's literal protocol end-to-end.
  VERDICT-PROPOSAL: one provenance tag — [V-code] (cite file:line) / [V-db] (cite query) /
               [V-probe] (cite the probe) / [C] (single-session, unverified) /
               [X] (refuted; say what supersedes it) — plus one sentence. This is a PROPOSAL:
               the receiving session/owner assigns the final tag after checking your probe.
  PHASE-LOG:   one ledger-ready line: "Phase N — reviewer(<model-id>) — <date> — <found> [proposed]"
'@

if ($ProjectRules -and (Test-Path $ProjectRules)) {
  $Contract += "`n`n--- PROJECT GROUND RULES (binding) ---`n" + (Get-Content -Raw $ProjectRules)
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
