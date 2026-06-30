# Lab 10 — deploy QuickNotes to Hugging Face Spaces
#
# Prerequisites:
#   1. HF account + token: https://huggingface.co/settings/tokens (write)
#   2. hf CLI: pip install -U huggingface_hub
#   3. Login once: hf auth login
#
# Usage (PowerShell):
#   $env:HF_SPACE = "quicknotes-lab10"   # optional; default below
#   .\cloud\scripts\deploy-hf-space.ps1

$ErrorActionPreference = "Stop"
$SpaceName = if ($env:HF_SPACE) { $env:HF_SPACE } else { "quicknotes-lab10" }
if ($env:HF_USER) {
    $User = $env:HF_USER
} else {
    $whoami = hf auth whoami 2>&1 | Out-String
    if ($whoami -match 'user=(\S+)') { $User = $Matches[1] }
    else { $User = "selysecr" }
}
$RepoId = "$User/$SpaceName"
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Src = Join-Path $Root "cloud\hf-space"

Write-Host "==> Creating HF Docker Space: $RepoId"
hf repos create $RepoId --type space --space-sdk docker --public --exist-ok

Write-Host "==> Uploading Space files..."
hf upload $RepoId $Src --repo-type space --commit-message "Lab 10: QuickNotes from ghcr.io"

$Url = "https://$User-$SpaceName.hf.space"
Write-Host ""
Write-Host "Space URL: $Url"
Write-Host "Health:    $Url/health"
Write-Host "Wait for HF build, then run:"
Write-Host "  curl -v $Url/health"
