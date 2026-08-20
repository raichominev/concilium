# concilium-forge.ps1 - run one FORGE round on one seat (Windows sibling of concilium-forge.sh).
#
# The forge is the concilium's generative mode: seats produce ORIGINAL ideas against an open
# question, read each other's ideas from a shared register, and BUILD on them. Nobody judges
# anybody. No verdict, no five blocks, no ratification - that is review mode. Read
# references/forge-mode.md first.
#
#   .\concilium-forge.ps1 -Seat cursor -Round 1 -Brief brief.md
#   .\concilium-forge.ps1 -Seat kimi   -Round 2 -Brief brief.md -Register IDEAS.md -Out .\forge-out
#
# EDITING RULE: keep STRING LITERALS pure ASCII (no BOM here; PS 5.1 reads Windows-1252 and an em
# dash contributes byte 0x94 = a smart quote that TERMINATES the literal).

param(
  [Parameter(Mandatory=$true)][ValidateSet("codex","cursor","grok","kimi")][string]$Seat,
  [Parameter(Mandatory=$true)][int]$Round,
  [Parameter(Mandatory=$true)][string]$Brief,
  [string]$Register,
  [string]$Out = ".\forge-out",
  [string]$Model,
  [string]$Effort = "max"
)

$ErrorActionPreference = "Continue"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Test-Path $Brief)) { Write-Error "brief not found: $Brief"; exit 3 }
New-Item -ItemType Directory -Force -Path $Out | Out-Null

$Prompt = Get-Content -Raw -Encoding UTF8 $Brief

if ($Register -and (Test-Path $Register)) {
  $reg = Get-Content -Raw -Encoding UTF8 $Register
  $instr = @"

--- IDEA REGISTER (every seat's work so far, curated) ---
$reg

--- ROUND $Round INSTRUCTION ---
1. BUILD ON ANOTHER SEAT'S IDEA. Pick at least two entries that are NOT yours and extend, combine,
   invert or generalise them into something neither seat proposed. Do not evaluate or rank them.
   Name the ids you built on.
2. DESIGN ONE EXPERIMENT you would run first, in enough detail that someone else could execute it:
   the join or query, the fixture, what counts as informative, what would make you abandon the
   direction, and what a FAILURE would teach. Failure is a valid outcome worth logging.
3. PROPOSE NEW ideas the register does not contain. Empty cells are worth more than full ones.

Output strict JSON, nothing else:
{"built_on":[{"id":"<seat>-r$Round-<n>","builds_on":["<id>"],"idea":"...","what_neither_said":"..."}],
 "experiment":{"name":"...","join_or_query":"...","fixture":"...","informative_if":"...","abandon_if":"...","failure_teaches":"..."},
 "new_ideas":[{"id":"<seat>-r$Round-n<n>","idea":"...","nearby_material":"...","cheapest_test":"..."}]}
"@
  $Prompt = $Prompt + $instr
}

$dest = Join-Path $Out "forge-$Seat-r$Round.txt"
Write-Host ">> forge seat=$Seat round=$Round prompt=$($Prompt.Length) chars -> $dest" -ForegroundColor DarkGray

switch ($Seat) {
  "codex" {
    if (-not $Model) { $Model = "gpt-5.6-sol" }
    $Prompt | & codex exec -m $Model -s read-only --skip-git-repo-check -c model_reasoning_effort=$Effort |
      Out-File -Encoding UTF8 $dest
  }
  { $_ -in @("cursor","grok") } {
    $args = @{ RawPrompt = $Prompt }
    if ($Model) { $args["Model"] = $Model }
    & (Join-Path $PSScriptRoot "concilium-review-cursor.ps1") @args | Out-File -Encoding UTF8 $dest
  }
  "kimi" {
    $args = @{ RawPrompt = $Prompt }
    if ($Model) { $args["Model"] = $Model }
    & (Join-Path $PSScriptRoot "concilium-review-kimi.ps1") @args | Out-File -Encoding UTF8 $dest
  }
}

$body = Get-Content -Raw $dest -ErrorAction SilentlyContinue
if ($body -and ($body -match '"ideas"' -or $body -match '"built_on"')) {
  Write-Host ">> ok: $dest" -ForegroundColor DarkGray
} else {
  Write-Host ">> WARNING: no ideas/built_on JSON in $dest - check the run before counting this round" -ForegroundColor Red
}
