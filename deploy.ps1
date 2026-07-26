# Deploy Powerlink LLC site to GitHub Pages (powerlynq.com)
$ErrorActionPreference = "Stop"

$gitCmd = "C:\Users\tgkoe\tools\PortableGit\cmd"
$ghBin = "C:\Users\tgkoe\tools\gh\bin"
$env:Path = "$gitCmd;C:\Users\tgkoe\tools\PortableGit\bin;$ghBin;" + $env:Path

Set-Location $PSScriptRoot

Write-Host "==> Checking GitHub auth..." -ForegroundColor Cyan
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Not logged in. Starting browser login..." -ForegroundColor Yellow
  Write-Host "Complete the prompts in your browser, then return here." -ForegroundColor Yellow
  gh auth login --hostname github.com --git-protocol https --web
  if ($LASTEXITCODE -ne 0) { throw "GitHub login failed or was cancelled." }
}

gh auth setup-git | Out-Null

$user = (gh api user --jq .login).Trim()
if (-not $user) { throw "Could not read GitHub username." }
Write-Host "==> GitHub user: $user" -ForegroundColor Green

$repoName = "powerlynq.com"
$repoFull = "$user/$repoName"

# Does remote repo exist?
$repoExists = $false
gh repo view $repoFull 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $repoExists = $true }

if (-not $repoExists) {
  Write-Host "==> Creating public repo $repoFull and pushing..." -ForegroundColor Cyan
  gh repo create $repoName --public --description "Powerlink LLC website (powerlynq.com)" --source . --remote origin --push
  if ($LASTEXITCODE -ne 0) { throw "Failed to create/push repo." }
} else {
  Write-Host "==> Repo exists. Ensuring remote and pushing main..." -ForegroundColor Cyan
  $remotes = @(git remote)
  if ($remotes -notcontains "origin") {
    git remote add origin "https://github.com/$repoFull.git"
  } else {
    git remote set-url origin "https://github.com/$repoFull.git"
  }
  git push -u origin main
  if ($LASTEXITCODE -ne 0) { throw "git push failed." }
}

# Ensure CNAME is present and pushed
$cnamePath = Join-Path $PSScriptRoot "CNAME"
if ((Get-Content $cnamePath -Raw).Trim() -ne "powerlynq.com") {
  Set-Content -Path $cnamePath -Value "powerlynq.com" -NoNewline
  git add CNAME
  git commit -m "Set custom domain CNAME to powerlynq.com" 2>$null
  git push origin main
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
gh api -X POST "repos/$repoFull/pages" --input $pagesJson 2>$null | Out-Null
# Update Pages config
gh api -X PUT "repos/$repoFull/pages" --input $pagesJson
if ($LASTEXITCODE -ne 0) {
  Write-Host "Pages API update returned non-zero; check Settings → Pages in the browser." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Deployed to GitHub" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Repo:     https://github.com/$repoFull"
Write-Host "GitHub:   https://$user.github.io/$repoName/"
Write-Host "Custom:   https://powerlynq.com  (after Namecheap DNS)"
Write-Host ""
Write-Host "NAMECHEAP → Domain List → powerlynq.com → Advanced DNS" -ForegroundColor Yellow
Write-Host "  Remove old Wix / parking / URL redirect records first."
Write-Host "  Then add:"
Write-Host "  A     @     185.199.108.153"
Write-Host "  A     @     185.199.109.153"
Write-Host "  A     @     185.199.110.153"
Write-Host "  A     @     185.199.111.153"
Write-Host "  CNAME www   $user.github.io."
Write-Host ""
Write-Host "After DNS works: GitHub → Settings → Pages → Enforce HTTPS" -ForegroundColor Cyan
