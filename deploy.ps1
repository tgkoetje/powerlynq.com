# Deploy Powerlink LLC site to GitHub Pages (powerlynq.com)
# Note: native tools (gh/git) write to stderr often - do not use Stop for those calls.
$ErrorActionPreference = "Continue"

$gitCmd = "C:\Users\tgkoe\tools\PortableGit\cmd"
$ghBin = "C:\Users\tgkoe\tools\gh\bin"
$env:Path = "$gitCmd;C:\Users\tgkoe\tools\PortableGit\bin;$ghBin;" + $env:Path

Set-Location $PSScriptRoot

function Test-GhAuth {
  # Returns $true if logged in. Captures stderr so PowerShell will not treat it as fatal.
  $prev = $ErrorActionPreference
  $ErrorActionPreference = "SilentlyContinue"
  $null = & gh auth status 2>&1
  $ok = ($LASTEXITCODE -eq 0)
  $ErrorActionPreference = $prev
  return $ok
}

Write-Host "==> Checking GitHub auth..." -ForegroundColor Cyan
if (-not (Test-GhAuth)) {
  Write-Host "Not logged in. Starting browser login..." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "A browser window should open. If not, copy the one-time code when prompted." -ForegroundColor Yellow
  Write-Host "Complete login, then this script will continue." -ForegroundColor Yellow
  Write-Host ""
  & gh auth login --hostname github.com --git-protocol https --web
  if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Login did not complete. Run this manually, then re-run deploy.ps1:" -ForegroundColor Red
    Write-Host '  gh auth login --hostname github.com --git-protocol https --web' -ForegroundColor White
    exit 1
  }
  if (-not (Test-GhAuth)) {
    Write-Host "Still not logged in after auth flow. Re-run: .\deploy.ps1" -ForegroundColor Red
    exit 1
  }
}

Write-Host "==> Logged in." -ForegroundColor Green
& gh auth setup-git 2>&1 | Out-Null

$user = (& gh api user --jq .login 2>$null)
if (-not $user) {
  Write-Host "Could not read GitHub username. Try: gh auth login" -ForegroundColor Red
  exit 1
}
$user = $user.Trim()
Write-Host "==> GitHub user: $user" -ForegroundColor Green

$repoName = "powerlynq.com"
$repoFull = "$user/$repoName"

# Does remote repo exist?
$prev = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$null = & gh repo view $repoFull 2>&1
$repoExists = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $prev

if (-not $repoExists) {
  Write-Host "==> Creating public repo $repoFull and pushing..." -ForegroundColor Cyan
  & gh repo create $repoName --public --description "Powerlink LLC website (powerlynq.com)" --source . --remote origin --push
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create/push repo." -ForegroundColor Red
    exit 1
  }
} else {
  Write-Host "==> Repo exists. Ensuring remote and pushing main..." -ForegroundColor Cyan
  $remotes = @(& git remote 2>$null)
  if ($remotes -notcontains "origin") {
    & git remote add origin "https://github.com/$repoFull.git"
  } else {
    & git remote set-url origin "https://github.com/$repoFull.git"
  }
  & git push -u origin main
  if ($LASTEXITCODE -ne 0) {
    Write-Host "git push failed." -ForegroundColor Red
    exit 1
  }
}

# Ensure CNAME is present and pushed
$cnamePath = Join-Path $PSScriptRoot "CNAME"
$cnameVal = (Get-Content $cnamePath -Raw -ErrorAction SilentlyContinue)
if (-not $cnameVal -or $cnameVal.Trim() -ne "powerlynq.com") {
  Set-Content -Path $cnamePath -Value "powerlynq.com" -NoNewline
  & git add CNAME
  & git commit -m "Set custom domain CNAME to powerlynq.com" 2>$null
  & git push origin main
}

Write-Host "==> Configuring GitHub Pages..." -ForegroundColor Cyan
$pagesJson = Join-Path $env:TEMP "gh-pages-config.json"
@'
{
  "cname": "powerlynq.com",
  "source": {
    "branch": "main",
    "path": "/"
  }
}
'@ | Set-Content -Path $pagesJson -Encoding ascii

# Enable Pages (ignore error if already on)
$ErrorActionPreference = "SilentlyContinue"
$null = & gh api -X POST "repos/$repoFull/pages" --input $pagesJson 2>&1
$null = & gh api -X PUT "repos/$repoFull/pages" --input $pagesJson 2>&1
$pagesOk = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = "Continue"

if (-not $pagesOk) {
  Write-Host "Pages API update had an issue - check Settings > Pages in the browser." -ForegroundColor Yellow
  Write-Host "  https://github.com/$repoFull/settings/pages" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Deployed to GitHub" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Repo:     https://github.com/$repoFull"
Write-Host "GitHub:   https://$user.github.io/$repoName/"
Write-Host "Custom:   https://powerlynq.com  (after Namecheap DNS)"
Write-Host ""
Write-Host "NAMECHEAP - Domain List - powerlynq.com - Advanced DNS" -ForegroundColor Yellow
Write-Host "  Remove old Wix / parking / URL redirect records first."
Write-Host "  Then add:"
Write-Host '  A record, Host @, Value 185.199.108.153'
Write-Host '  A record, Host @, Value 185.199.109.153'
Write-Host '  A record, Host @, Value 185.199.110.153'
Write-Host '  A record, Host @, Value 185.199.111.153'
Write-Host "  CNAME record, Host www, Value $user.github.io."
Write-Host ""
Write-Host "After DNS works: GitHub > Settings > Pages > Enforce HTTPS" -ForegroundColor Cyan
