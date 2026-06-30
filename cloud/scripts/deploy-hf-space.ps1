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
$User = if ($env:HF_USER) { $env:HF_USER } else { "selysecr332" }
$RepoId = "$User/$SpaceName"
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Src = Join-Path $Root "cloud\hf-space"
$Work = Join-Path $env:TEMP "hf-space-$SpaceName"

Write-Host "==> Creating HF Docker Space: $RepoId"
hf repo create $RepoId --type space --space-sdk docker --private $false

if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
New-Item -ItemType Directory -Path $Work | Out-Null
Copy-Item (Join-Path $Src "Dockerfile") $Work
Copy-Item (Join-Path $Src "README.md") $Work

Set-Location $Work
git init -q
git checkout -b main 2>$null
git add Dockerfile README.md
git -c user.name="lab10" -c user.email="lab10@local" commit -q -m "Lab 10: QuickNotes from ghcr.io"
git remote add origin "https://huggingface.co/spaces/$RepoId"
Write-Host "==> Pushing to HF (may prompt for credentials)..."
git push -u origin main --force

$Url = "https://$User-$SpaceName.hf.space"
Write-Host ""
Write-Host "Space URL: $Url"
Write-Host "Health:    $Url/health"
Write-Host "Wait for HF build, then run:"
Write-Host "  curl -v $Url/health"
