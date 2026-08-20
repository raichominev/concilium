# concilium-review-cursor.ps1 — cross-model review seat via the Cursor Agent CLI (Windows).
#
# Runs an xAI model (default Grok 4.6 at extra-high effort) on Cursor-subscription auth — no xAI
# API key, no metered per-token billing. Sibling of concilium-review.ps1 (codex/GPT) and
# concilium-review-kimi.ps1 (Moonshot). Same contract, same five blocks, same verdict discipline.
#
# The review contract lives in references/contract.md (single source of truth shared with every
# wrapper) — edit it there, not here.
#
# Modes:
#   -Claim "<text>"       : falsification-probe review of a claim
#   -Diff                 : review the working-tree diff of -RepoDir (embedded in the prompt)
#   -Base <branch>        : with -Diff, diff against a base branch instead of the working tree
#   -RawPrompt "<text>"   : send a bare prompt with NO contract (calibration probes, smoke tests)
#   -Mechanical           : mechanical tier (cursor-grok-4.6-medium)
#   -Model <id>           : effort is BAKED INTO the model id here — there is no effort flag:
#                           ...-low | -medium | -high | -xhigh, each with a `-fast` sibling.
#                           `cursor-agent --list-models` for the current roster.
#   -AllowFast            : permit a `-fast` id (refused otherwise: different serving path, so this
#                           seat's calibration does not transfer to it)
#   -ProjectRules <file>  : curated ground-rules file appended to the contract
#   -PriorRounds <file>   : loop mode — prior rounds' probes + the objection (new evidence path)
#   -AutoRules            : also inject AGENTS.md/CLAUDE.md into the contract. OFF by default: this
#                           CLI already loads project CLAUDE.md/AGENTS.md natively from the workspace.
#   -NoHomeIsolation      : run under the real profile (see HOME ISOLATION — expect broken shell)
#   -WatchPaths a,b,c     : blind-integrity tripwire — snapshot NTFS last-access times under these
#                           paths and report any read during the run. Tripwire, not proof.
#
# SECURITY — what this seat does and does not contain (measured 2026-08-19, CLI 2026.08.11):
#   * `--mode ask` DOES block writes: two probes asked for a file, both refused, nothing on disk.
#     A real read-only constraint, unlike the kimi seat.
#   * `--force` here only bypasses the interactive command allowlist that headless cannot answer
#     (approvalMode=allowlist rejects unlisted commands with a bare "Rejected:"). With `--mode ask`
#     it buys read commands, not writes. NEVER pair -Force-style flags with agent mode.
#   * `--sandbox enabled` is macOS/Linux ONLY — it errors out on Windows.
#   * The workspace is NOT a boundary: a canary outside it was read by absolute path and returned
#     verbatim. Anything this account can read is in scope and reaches Cursor's backend. Real
#     isolation is an OS-level job (VM, or a separate account with ACLs).
#
# HOME ISOLATION (on by default, and load-bearing):
#   The Cursor CLI imports Claude Code's user-level hooks/skills/plugins and no flag disables the
#   import. On Windows it ALWAYS builds the hook payload wrapper in PowerShell syntax
#       Get-Content -LiteralPath '<payload>' -Raw | & { $input | <hook command> }
#   but runs it with the shell it detects from MSYSTEM/SHELL. Launched from Git Bash it picks bash,
#   which cannot parse `& {`, so every hook dies with
#       --: eval: line 1: syntax error near unexpected token `&'
#   and EVERY SHELL TOOL CALL IS REJECTED - the reviewer then silently reviews with no probes. The
#   hook COMMAND does not matter: a hook whose command is literally `exit 0` fails the same way
#   (measured 2026-08-19). Launching from cmd/PowerShell - or from a shim that clears MSYSTEM and
#   EXEPATH at the cmd level, since MSYS re-injects MSYSTEM into every Win32 child - makes the same
#   hooks run. This wrapper instead points HOME/USERPROFILE at an empty directory and passes
#   CURSOR_CONFIG_DIR at the real profile for auth, which holds whatever shell launched it. Side
#   benefit: the reviewer cannot read ~/.claude - useful for blind rounds. Project-level .claude/
#   hooks inside -RepoDir are still loaded; a "Rejected: ... syntax error" in the output is that.
#
# Run in BACKGROUND with a full ~10 min timeout from the first call: real reviews take 5-15 min.
#
# EDITING RULE: keep STRING LITERALS pure ASCII. This file has no BOM, so PowerShell 5.1 decodes it
# as Windows-1252; an em dash (E2 80 94) then contributes byte 0x94 = the smart quote ", which
# TERMINATES the literal and the whole script fails to parse. Comments are safe (they end at EOL).

param(
  [string]$Claim,
  [switch]$Diff,
  [string]$Base,
  [string]$RawPrompt,
  [switch]$Mechanical,
  [string]$Model,
  [switch]$AllowFast,
  [string]$ProjectRules,
  [string]$PriorRounds,
  [switch]$AutoRules,
  [switch]$NoHomeIsolation,
  [switch]$NoReasoningBoost,
  [string]$RepoDir = "",
  [string]$WatchPaths
)

$ErrorActionPreference = "Continue"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $Model) { $Model = if ($Mechanical) { "cursor-grok-4.6-medium" } else { "cursor-grok-4.6-xhigh" } }
if ($Model -like "*-fast" -and -not $AllowFast) {   # -like is case-insensitive, matching the sh guard
  Write-Error "Refusing model '$Model': the -fast lane is a different serving path and does not inherit this seat's calibration. Pass -AllowFast to override deliberately."
  exit 2
}

if (-not $Diff -and -not $RawPrompt -and [string]::IsNullOrWhiteSpace($Claim)) {
  Write-Error "Provide -Claim `"<text>`", -Diff, or -RawPrompt `"<text>`". See the header for usage."
  exit 2
}

if (-not $RepoDir) {
  $RepoDir = (& git rev-parse --show-toplevel 2>$null)
  if (-not $RepoDir) { $RepoDir = (Get-Location).Path }
}
$RepoDir = (Resolve-Path -LiteralPath $RepoDir).Path

# --- locate the CLI -----------------------------------------------------------------------------
$Agent = $env:CURSOR_AGENT
if (-not $Agent) {
  $onPath = Get-Command cursor-agent -ErrorAction SilentlyContinue
  if ($onPath) { $Agent = $onPath.Source }
  else {
    $local = Join-Path $env:LOCALAPPDATA "cursor-agent\cursor-agent.cmd"
    if (Test-Path $local) { $Agent = $local }
  }
}
if (-not $Agent) {
  Write-Error "cursor-agent not found. Install: powershell -c `"irm 'https://cursor.com/install?win32=true' | iex`" then run 'cursor-agent login'."
  exit 3
}

# --- blind-integrity tripwire --------------------------------------------------------------------
# Enumeration returns CACHED directory-entry timestamps; query each file directly for the real one.
function Get-AccessMap([string[]]$roots) {
  $m = @{}
  foreach ($r in $roots) {
    if (-not (Test-Path -LiteralPath $r)) { continue }
    $item = Get-Item -LiteralPath $r -Force
    $paths = if ($item.PSIsContainer) {
      (Get-ChildItem -LiteralPath $r -Recurse -File -Force -ErrorAction SilentlyContinue).FullName
    } else { @($item.FullName) }
    foreach ($p in $paths) {
      $fi = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
      if ($fi) { $m[$p] = $fi.LastAccessTimeUtc }
    }
  }
  return $m
}
$WatchPre = $null
if ($WatchPaths) {
  $watchList = $WatchPaths -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  $WatchPre = Get-AccessMap $watchList
  Write-Host ">> blind-integrity watch: $($WatchPre.Count) files across $($watchList.Count) path(s)" -ForegroundColor DarkGray
}

# --- contract assembly (identical rules to the other wrappers) -----------------------------------
$ContractPath = Join-Path $PSScriptRoot "..\references\contract.md"
if (-not (Test-Path $ContractPath)) { Write-Error "Contract file not found: $ContractPath"; exit 3 }
$Contract = Get-Content -Raw -Encoding UTF8 $ContractPath

if ($ProjectRules -and (Test-Path $ProjectRules)) {
  $Contract += "`n`n--- PROJECT GROUND RULES (binding) ---`n" + (Get-Content -Raw $ProjectRules)
}
elseif ($AutoRules) {
  foreach ($f in @((Join-Path $RepoDir "AGENTS.md"), (Join-Path $RepoDir ".claude\CLAUDE.md"), (Join-Path $RepoDir "CLAUDE.md"))) {
    if (Test-Path $f) {
      $Contract += "`n`n--- PROJECT INSTRUCTIONS ($(Split-Path -Leaf $f)) ---`n" + (Get-Content -Raw $f)
      Write-Host ">> injected $(Split-Path -Leaf $f)" -ForegroundColor DarkGray
      break
    }
  }
}

if ($PriorRounds -and (Test-Path $PriorRounds)) {
  $Contract += "`n`n--- PRIOR ROUNDS (do NOT repeat these probes; take a new evidence path; address the objection) ---`n" + (Get-Content -Raw $PriorRounds)
}

# Reasoning boost - ON by default for THIS seat. Measured 2026-08-19 on the 14-item prediction
# packet: this seat over-called WIN, and the block cut its false-alarm rate 33.3% to 6.7%
# (d-prime 0.51 to 1.58, +13.3 pp accuracy), the largest gain of any seat. -NoReasoningBoost to skip.
# WARNING: measured in PREDICTION mode; these wrappers run ADJUDICATION mode, where chairs already
# over-refute (setup.md). If reviews turn reflexively negative, turn it off and say so.
$BoostPath = Join-Path $PSScriptRoot "..\references\reasoning-boost.md"
if (-not $NoReasoningBoost -and (Test-Path $BoostPath)) {
  $Contract += "`n`n" + (Get-Content -Raw -Encoding UTF8 $BoostPath)
  Write-Host ">> reasoning boost ON (-NoReasoningBoost to disable)" -ForegroundColor DarkGray
}

$AgentVersion = (& $Agent --version 2>$null | Select-Object -First 1)
$Contract += "`n`nRuntime provenance (use in PHASE-LOG): model=$Model, seat=cursor, harness=cursor-agent $AgentVersion."

if ($RawPrompt) {
  $Prompt = $RawPrompt
}
elseif ($Diff) {
  Push-Location $RepoDir
  try {
    if ($Base) { $d = (& git diff $Base 2>&1 | Out-String) } else { $d = (& git diff HEAD 2>&1 | Out-String) }
  } finally { Pop-Location }
  if ([string]::IsNullOrWhiteSpace($d)) { Write-Error "No diff to review in $RepoDir"; exit 2 }
  $Prompt = "$Contract`n`n--- DIFF UNDER REVIEW (repo: $RepoDir) ---`n$d"
}
else {
  $Prompt = "$Contract`n`n--- CLAIM UNDER REVIEW ---`n$Claim"
}

# --- run ------------------------------------------------------------------------------------------
# The prompt goes via STDIN. As an argv argument the Windows .cmd shim mangles it: a multi-line
# prompt arrives truncated at line 1 and the model answers a question you never asked.
$RealCursorCfg = $env:CURSOR_CONFIG_DIR
if (-not $RealCursorCfg) { $RealCursorCfg = Join-Path $env:USERPROFILE ".cursor" }

$savedHome = $env:HOME; $savedProfile = $env:USERPROFILE; $savedCfg = $env:CURSOR_CONFIG_DIR
$IsoHome = $null
if (-not $NoHomeIsolation) {
  $IsoHome = Join-Path $env:TEMP ("concilium-cursor-home-" + [guid]::NewGuid().ToString("N").Substring(0,8))
  New-Item -ItemType Directory -Force -Path $IsoHome | Out-Null
  $env:HOME = $IsoHome; $env:USERPROFILE = $IsoHome; $env:CURSOR_CONFIG_DIR = $RealCursorCfg
}

Write-Host ">> cursor-agent -p --trust --force --mode ask --model $Model (prompt $($Prompt.Length) chars via stdin, cwd=$RepoDir)" -ForegroundColor DarkGray

$agentArgs = @("-p", "--trust", "--force", "--mode", "ask", "--model", $Model, "--output-format", "json")
Push-Location $RepoDir
try   { $RawJson = ($Prompt | & $Agent @agentArgs 2>&1 | Out-String) }
finally {
  Pop-Location
  $env:HOME = $savedHome; $env:USERPROFILE = $savedProfile; $env:CURSOR_CONFIG_DIR = $savedCfg
  if ($IsoHome) { Remove-Item -LiteralPath $IsoHome -Recurse -Force -ErrorAction SilentlyContinue }
}
$code = $LASTEXITCODE

# json mode emits one {"type":"result",...} object carrying the review in .result
$Raw = ""
foreach ($line in ($RawJson -split "`r?`n")) {
  $t = $line.Trim()
  if (-not $t.StartsWith("{")) { continue }
  try { $o = $t | ConvertFrom-Json } catch { continue }
  if ($o.result -is [string]) { $Raw = $o.result }
}
if (-not $Raw) { $Raw = $RawJson }
Write-Output $Raw

# --- never trust the exit code --------------------------------------------------------------------
if (-not $RawPrompt) {
  $blocks = @("PROBE:", "ALT:", "CAVEAT:", "VERDICT-PROPOSAL:", "PHASE-LOG:") | Where-Object { $Raw -match [regex]::Escape($_) }
  if ($blocks.Count -lt 5) {
    Write-Host ">> WARNING: only $($blocks.Count)/5 contract blocks present - treat this run as FAILED regardless of exit code $code" -ForegroundColor Red
  }
}
# Match the hook signature, not a bare "Rejected:" — reviewers quote that string when discussing
# this very failure mode, which made the loose check cry wolf on a healthy run.
if ($Raw -match "Rejected: Hook blocked") {
  Write-Host ">> WARNING: a tool call was REJECTED by an imported .claude hook - shell probes were blocked and the review ran without them (see HOME ISOLATION in this file's header; project-level .claude/ hooks are still loaded)." -ForegroundColor Red
}

if ($WatchPre) {
  $wpost = Get-AccessMap ($WatchPaths -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  $touched = @($wpost.Keys | Where-Object { $WatchPre.ContainsKey($_) -and $wpost[$_] -gt $WatchPre[$_] })
  if ($touched.Count) {
    Write-Host ">> BLIND-INTEGRITY TRIPPED: $($touched.Count) watched file(s) accessed during the run" -ForegroundColor Red
    foreach ($f in ($touched | Select-Object -First 20)) { Write-Host "   ! $f" -ForegroundColor Red }
    Write-Host "   Treat this round as CONTAMINATED unless you can attribute the access to another process." -ForegroundColor Red
  } else {
    Write-Host ">> blind integrity OK ($($WatchPre.Count) watched files unread)" -ForegroundColor DarkGray
  }
}

exit $code
