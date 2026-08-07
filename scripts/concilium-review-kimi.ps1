# concilium-review-kimi.ps1 — adversarial cross-model review via the Kimi Desktop daimon CLI
# (Moonshot subscription auth inherited from the installed Kimi Desktop app; no API key entered here).
# Third seat alongside scripts/concilium-review.ps1 (codex/GPT). See SKILL.md for the method.
#
# The review contract lives in references/contract.md (single source of truth shared with the codex
# wrappers) — edit it there, not here.
#
# Modes:
#   -Claim "<text>"        : falsification-probe review of a claim
#   -Diff                  : review the working-tree diff of -RepoDir (diff is embedded in the prompt;
#                            kimi has no native `review --uncommitted` like codex)
#   -Base <branch>         : with -Diff, diff against a base branch instead of the working tree
#   -RawPrompt "<text>"    : send a bare prompt with NO contract (calibration probes, smoke tests)
#   -Mechanical            : mechanical tier — verify a known claim with one probe
#   -ProjectRules <file>   : optional project ground-rules file appended to the contract
#   -PriorRounds <file>    : loop mode — prior rounds' probes + the objection (new evidence path)
#   -AutoRules             : opt in to auto-bridging AGENTS.md/CLAUDE.md into the contract.
#                            OFF by default for this seat, unlike the codex wrappers: measured
#                            2/2 runs with the injection die on a bare "Connection error." and
#                            2/2 without it succeed (pitfalls #18). Prefer -ProjectRules <file>.
#   -SandboxFrom <dir>     : copy <dir> to a throwaway working copy, run the agent there, report
#                            what it created/modified/deleted, then delete the copy. Blast-radius
#                            control for a seat with no OS sandbox — NOT containment.
#   -SandboxRoot <dir>     : where throwaway copies live (default %TEMP%\concilium-kimi-sandbox)
#   -KeepSandbox           : keep the copy after the run instead of deleting it (for inspection)
#   -WatchPaths a,b,c      : blind-integrity tripwire. Snapshot NTFS last-access times under these
#                            paths before the run and report any that were read during it — for
#                            BLIND rounds, where an escape contaminates the answer rather than
#                            damaging anything. Tripwire, not proof (pitfalls #21).
#   -Approval manual|yolo  : agent permission mode (see SECURITY below)
#   -ShowLog               : pass the runtime's stderr through instead of discarding it
#
# SECURITY — this seat is NOT sandboxed the way codex is.
#   `kimi-daimon run --prompt` is documented as running "one non-interactive local-control turn with
#   yolo permissions". There is no process-level sandbox flag equivalent to codex's `-s read-only`,
#   and the hosted-agent config accepts only approvalMode "manual" or "yolo" ("readonly"/"plan" are
#   rejected by config validation). This wrapper defaults to "manual"; -Approval yolo is opt-in.
#   Either way it is an agent-config constraint, not an OS sandbox. workDir is where the agent
#   starts, NOT a boundary: measured 2026-08-07, a canary file outside workDir was read by
#   absolute path and its contents returned (pitfalls #20). It reads whatever the user account
#   can read, and what it reads reaches the provider.
#   -SandboxFrom bounds the damage and proves what was touched; it does not contain the agent.
#   Real isolation = separate OS account with ACLs, or a VM. Do not point this at a tree whose
#   loss you would mind, and do not run it on a machine holding material that must not leave.
#
# Auth/state: credentials, model list and runtime paths are inherited from the Kimi Desktop app's
# provisioned share (daimon-share\daimon\config.json). This wrapper NEVER edits that file — it
# writes an isolated copy under daimon-share\concilium\ (same directory ACL, no new secret exposure)
# so the CLI never contends with the running desktop app for agents\main\runner.lock.
#
# Node: the bundle requires Node 24.15.x and ships none; we run Electron as Node (Kimi.exe with
# ELECTRON_RUN_AS_NODE=1) and call the CLI entry directly, which also dodges cmd.exe's 8191-char
# argv limit that the shipped kimi-daimon.cmd shim would impose on a full contract prompt.

param(
  [string]$Claim,
  [switch]$Diff,
  [string]$Base,
  [switch]$Mechanical,
  [string]$ProjectRules,
  [string]$PriorRounds,
  [switch]$AutoRules,
  [string]$RawPrompt,
  [string]$Model  = "k3-agent",
  [ValidateSet("low","high","max")][string]$Effort = "max",
  [ValidateSet("manual","yolo")][string]$Approval = "manual",
  [string]$RepoDir = "",
  [string]$SandboxFrom,
  [string]$SandboxRoot,
  [switch]$KeepSandbox,
  [string]$WatchPaths,
  [switch]$ShowLog
)

if ($Mechanical) {
  if (-not $PSBoundParameters.ContainsKey('Model'))  { $Model  = "k2d6-agent" }
  if (-not $PSBoundParameters.ContainsKey('Effort')) { $Effort = "high" }
}

$ErrorActionPreference = "Continue"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- locate the Kimi install (env overrides for non-default installs) ---------------------------
$KimiExe = $env:CONCILIUM_KIMI_EXE
if (-not $KimiExe) { $KimiExe = Join-Path $env:LOCALAPPDATA "Programs\kimi-desktop\Kimi.exe" }
$Bundle  = $env:CONCILIUM_KIMI_BUNDLE
if (-not $Bundle)  { $Bundle  = Join-Path $env:APPDATA "kimi-desktop\daimon-bundle" }
$Share   = $env:CONCILIUM_KIMI_SHARE
if (-not $Share)   { $Share   = Join-Path $env:APPDATA "kimi-desktop\daimon-share" }

$CliJs   = Join-Path $Bundle "app\daimon\dist\src\runner\cli.js"
$AppCfg  = Join-Path $Share  "daimon\config.json"
$OcCfg   = Join-Path $Share  "daimon\runtime\openclaw-empty.json"
$Home2   = Join-Path $Share  "concilium"
$MyCfg   = Join-Path $Home2  "config.json"

foreach ($p in @($KimiExe, $CliJs, $AppCfg)) {
  if (-not (Test-Path $p)) { Write-Error "Kimi component not found: $p (is Kimi Desktop installed and signed in?)"; exit 3 }
}

if (-not $RepoDir) {
  $RepoDir = (& git rev-parse --show-toplevel 2>$null)
  if (-not $RepoDir) { $RepoDir = (Get-Location).Path }
}
$RepoDir = (Resolve-Path -LiteralPath $RepoDir).Path

# --- disposable working copy --------------------------------------------------------------------
# This seat has no OS sandbox (see SECURITY above). -SandboxFrom is the blast-radius control:
# copy the source tree to a throwaway directory, point the agent at the copy, and diff it after.
# It bounds damage and shows you what was touched; it is NOT containment (the agent is not
# confined to workDir — see references/pitfalls.md #20).
$SandboxDir = $null
$PreManifest = $null
function Get-TreeManifest([string]$root) {
  $m = @{}
  Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $rel = $_.FullName.Substring($root.Length).TrimStart('\')
    $m[$rel] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
  }
  return $m
}
if ($SandboxFrom) {
  $src = (Resolve-Path -LiteralPath $SandboxFrom).Path
  if (-not $SandboxRoot) { $SandboxRoot = Join-Path $env:TEMP "concilium-kimi-sandbox" }
  $stamp = (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0,6))
  $SandboxDir = Join-Path $SandboxRoot $stamp
  New-Item -ItemType Directory -Force -Path $SandboxDir | Out-Null
  # /MIR would delete; plain copy + excludes. Secrets and VCS metadata never enter the copy.
  $xd = @(".git","node_modules","__pycache__",".venv","venv",".mypy_cache",".pytest_cache")
  $xf = @("*.env",".env","*.pem","*.key","id_rsa*","*.pfx","*.p12","credentials*","*.sqlite-journal")
  $rc = @($src, $SandboxDir, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NP", "/R:1", "/W:1",
          "/XD") + $xd + @("/XF") + $xf
  & robocopy.exe @rc | Out-Null
  if ($LASTEXITCODE -ge 8) { Write-Error "sandbox copy failed (robocopy $LASTEXITCODE)"; exit 3 }
  $RepoDir = $SandboxDir
  $PreManifest = Get-TreeManifest $SandboxDir
  Write-Host ">> sandbox copy: $src -> $SandboxDir ($($PreManifest.Count) files)" -ForegroundColor DarkGray
}

# --- blind-integrity tripwire -------------------------------------------------------------------
# For a BLIND round the risk is not damage, it is contamination: if the agent wanders out of the
# sandbox and reads the real tree (or the answer key), the round is no longer blind. NTFS records
# last-access times, so snapshot them for the paths that must stay unread and re-check after.
# Tripwire, not proof — see references/pitfalls.md #21 for the false-positive/negative cases.
$WatchPre = $null
function Get-AccessMap([string[]]$roots) {
  # Enumeration (Get-ChildItem) returns the directory entry's CACHED timestamps, which lag behind
  # reality — measured: a file read mid-run still showed its pre-run access time via enumeration
  # while a direct Get-Item on the same path showed the update. Enumerate for paths, then query
  # each file directly for the authoritative value.
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
if ($WatchPaths) {
  $watchList = $WatchPaths -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  $WatchPre = Get-AccessMap $watchList
  Write-Host ">> blind-integrity watch: $($WatchPre.Count) files across $($watchList.Count) path(s)" -ForegroundColor DarkGray
}

# --- contract assembly (identical rules to the codex wrapper) -----------------------------------
$ContractPath = Join-Path $PSScriptRoot "..\references\contract.md"
if (-not (Test-Path $ContractPath)) { Write-Error "Contract file not found: $ContractPath"; exit 3 }
$Contract = Get-Content -Raw -Encoding UTF8 $ContractPath

if ($ProjectRules -and (Test-Path $ProjectRules)) {
  $Contract += "`n`n--- PROJECT GROUND RULES (binding) ---`n" + (Get-Content -Raw $ProjectRules)
}
elseif ($AutoRules) {
  # kimi-code does not load CLAUDE.md, and AGENTS.md pickup is not guaranteed — bridge explicitly.
  $agents    = Join-Path $RepoDir "AGENTS.md"
  $claudeDot = Join-Path $RepoDir ".claude\CLAUDE.md"
  $claudeTop = Join-Path $RepoDir "CLAUDE.md"
  if (Test-Path $agents) {
    $Contract += "`n`n--- PROJECT INSTRUCTIONS (AGENTS.md) ---`n" + (Get-Content -Raw $agents)
    Write-Host ">> injected AGENTS.md" -ForegroundColor DarkGray
  }
  elseif (Test-Path $claudeDot) {
    $Contract += "`n`n--- PROJECT INSTRUCTIONS (.claude/CLAUDE.md) ---`n" + (Get-Content -Raw $claudeDot)
    Write-Host ">> injected .claude/CLAUDE.md" -ForegroundColor DarkGray
  }
  elseif (Test-Path $claudeTop) {
    $Contract += "`n`n--- PROJECT INSTRUCTIONS (CLAUDE.md) ---`n" + (Get-Content -Raw $claudeTop)
    Write-Host ">> injected CLAUDE.md" -ForegroundColor DarkGray
  }
}

if ($PriorRounds -and (Test-Path $PriorRounds)) {
  $Contract += "`n`n--- PRIOR ROUNDS (do NOT repeat these probes; take a new evidence path; address the objection) ---`n" + (Get-Content -Raw $PriorRounds)
}

if (-not $Diff -and -not $RawPrompt -and [string]::IsNullOrWhiteSpace($Claim)) {
  Write-Error "Provide -Claim `"<text>`", -Diff, or -RawPrompt `"<text>`". See the header for usage."
  exit 2
}

# Provenance stamp: the model does not reliably know its own id, so the wrapper injects it.
$Prompt = ""
if ($RawPrompt) {
  $Prompt = $RawPrompt
}
else {
  $ContractFull = $Contract + "`n`nRuntime provenance (use in PHASE-LOG): model=$Model, effort=$Effort, seat=kimi."
  if ($Diff) {
    Push-Location $RepoDir
    try {
      if ($Base) { $d = (& git diff $Base 2>&1 | Out-String) } else { $d = (& git diff HEAD 2>&1 | Out-String) }
    } finally { Pop-Location }
    if ([string]::IsNullOrWhiteSpace($d)) { Write-Error "No diff to review in $RepoDir"; exit 2 }
    $Prompt = "$ContractFull`n`n--- DIFF UNDER REVIEW (repo: $RepoDir) ---`n$d"
  }
  else {
    $Prompt = "$ContractFull`n`n--- CLAIM UNDER REVIEW ---`n$Claim"
  }
}

# --- isolated daimon home: inherit the app's credentials, override model/effort/workDir ---------
New-Item -ItemType Directory -Force -Path $Home2, (Join-Path $Home2 "agents\main\agent") | Out-Null
$cfg = Get-Content -Raw -Encoding UTF8 $AppCfg | ConvertFrom-Json
if (-not $cfg.model.models.PSObject.Properties.Name.Contains($Model)) {
  Write-Error ("Model '$Model' not in the app config. Available: " + ($cfg.model.models.PSObject.Properties.Name -join ', '))
  exit 4
}
$cfg.model.current       = $Model
$cfg.model.thinkingLevel = $Effort
$cfg.agents.defaults.approvalMode        = $Approval
$cfg.agents.entries.main.workDir         = $RepoDir
$cfg.agents.entries.main.agentDir        = (Join-Path $Home2 "agents\main\agent")
# -Depth must exceed the provider/model graph (a shallow depth silently truncates it to strings),
# and the file must be BOM-less UTF-8 — Set-Content -Encoding UTF8 writes a BOM the runtime rejects.
[System.IO.File]::WriteAllText($MyCfg, ($cfg | ConvertTo-Json -Depth 64 -Compress), (New-Object System.Text.UTF8Encoding($false)))

$env:ELECTRON_RUN_AS_NODE   = "1"
$env:DAIMON_CONFIG_PATH     = $MyCfg
$env:DAIMON_BUNDLE_NODE_BIN = $KimiExe
$env:DAIMON_ADAPTER_PACKAGE_ROOT = Join-Path $Bundle "app\daimon"
$env:DAIMON_UV_PATH              = Join-Path $Bundle "runtime\uv\uv.exe"
$env:DAIMON_PYTHON_BASE_PATH     = Join-Path $Bundle "runtime\python\cpython-3.12\python.exe"
$env:DAIMON_RUNTIME_BINARY_PATH  = Join-Path $Bundle "bin\kimi-daimon.cmd"

Write-Host ">> kimi run --model $Model --thinking $Effort (approval=$Approval, workDir=$RepoDir)" -ForegroundColor DarkGray

# PowerShell 5.1 re-quotes native-command arguments and mangles any that contain `"` — the contract
# does, so `& $exe @args` word-splits it into bogus positional args. Build the command line ourselves
# with CommandLineToArgvW's rules (double the backslash run before a quote, escape the quote) and
# hand it to CreateProcess raw. Newlines are safe: only space and tab delimit arguments.
function ConvertTo-Win32Arg([string]$s) {
  $s = [regex]::Replace($s, '(\\*)"', '$1$1\"')
  $s = [regex]::Replace($s, '(\\+)$', '$1$1')
  return '"' + $s + '"'
}
$kimiArgs = @($CliJs, "run", "--config", $OcCfg, "--model", $Model, "--thinking", $Effort, "--prompt", $Prompt)

# Kimi.exe is a GUI-subsystem binary: its output does not survive redirection applied by a *parent*
# shell, so capture it here through our own pipes. The runtime interleaves its log lines with the
# assistant text — everything timestamped `... INFO|ERROR ...` is log, the rest is the answer.
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $KimiExe
$psi.Arguments = (($kimiArgs | ForEach-Object { ConvertTo-Win32Arg $_ }) -join ' ')
$psi.UseShellExecute        = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$psi.StandardErrorEncoding  = [System.Text.Encoding]::UTF8
$psi.WorkingDirectory       = $RepoDir
$proc = [System.Diagnostics.Process]::Start($psi)
$errTask = $proc.StandardError.ReadToEndAsync()
$out = $proc.StandardOutput.ReadToEnd()
$proc.WaitForExit()
$raw  = $out + $errTask.Result
$code = $proc.ExitCode
$lines = $raw -split "`r?`n"
if ($ShowLog) {
  $lines | ForEach-Object { Write-Output $_ }
} else {
  $lines | Where-Object { $_ -notmatch '^\d{4}-\d{2}-\d{2}T[\d:.]+Z\s+(INFO|WARN|ERROR|DEBUG)\s' } |
           ForEach-Object { Write-Output $_ }
  $err = $lines | Where-Object { $_ -match '^\d{4}-\d{2}-\d{2}T[\d:.]+Z\s+ERROR\s' }
  if ($err) { $err | ForEach-Object { Write-Error $_ } }
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

if ($SandboxDir) {
  $post = Get-TreeManifest $SandboxDir
  $created  = @($post.Keys  | Where-Object { -not $PreManifest.ContainsKey($_) })
  $deleted  = @($PreManifest.Keys | Where-Object { -not $post.ContainsKey($_) })
  $modified = @($post.Keys  | Where-Object { $PreManifest.ContainsKey($_) -and $PreManifest[$_] -ne $post[$_] })
  if ($created.Count -or $deleted.Count -or $modified.Count) {
    Write-Host ">> sandbox CHANGED: $($created.Count) created, $($modified.Count) modified, $($deleted.Count) deleted" -ForegroundColor Yellow
    foreach ($f in ($created  | Select-Object -First 20)) { Write-Host "   + $f" -ForegroundColor Yellow }
    foreach ($f in ($modified | Select-Object -First 20)) { Write-Host "   ~ $f" -ForegroundColor Yellow }
    foreach ($f in ($deleted  | Select-Object -First 20)) { Write-Host "   - $f" -ForegroundColor Yellow }
  } else {
    Write-Host ">> sandbox unchanged ($($post.Count) files verified)" -ForegroundColor DarkGray
  }
  if ($KeepSandbox) {
    Write-Host ">> sandbox kept: $SandboxDir" -ForegroundColor DarkGray
  } else {
    Remove-Item -LiteralPath $SandboxDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}
exit $code
