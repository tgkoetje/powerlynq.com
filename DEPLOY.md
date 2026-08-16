# Deploy powerlynq.com → GitHub Pages

## One-time setup

### 1. Log in to GitHub (required once)

Open **PowerShell** and run:

```powershell
$env:Path = "C:\Users\tgkoe\tools\PortableGit\cmd;C:\Users\tgkoe\tools\PortableGit\bin;C:\Users\tgkoe\tools\gh\bin;" + $env:Path
gh auth login --hostname github.com --git-protocol https --web
```

Follow the browser prompts. Choose **GitHub.com** → **HTTPS** → authenticate in browser → allow access.

### 2. Run deploy script

```powershell
cd C:\Users\tgkoe\powerlynq-site
.\deploy.ps1
```

This creates a public repo, pushes the site, enables GitHub Pages, and sets the custom domain `powerlynq.com`.

---

## Namecheap DNS (after repo exists)

In **Namecheap → Domain List → powerlynq.com → Manage → Advanced DNS**, remove old Wix records and set:

| Type | Host | Value | TTL |
|------|------|--------|-----|
| **A** | `@` | `185.199.108.153` | Automatic |
| **A** | `@` | `185.199.109.153` | Automatic |
| **A** | `@` | `185.199.110.153` | Automatic |
| **A** | `@` | `185.199.111.153` | Automatic |
| **CNAME** | `www` | `<your-github-username>.github.io.` | Automatic |

Also delete any leftover **URL Redirect**, **parking**, or **Wix** records that conflict.

## Synergy Analyzer (`/analyzer/`)

The analyzer is a static build in `analyzer/`. Grok runs on a **Cloudflare Worker** (API key never ships in this repo).

1. In `C:\Users\tgkoe\powerlynq-synergy-analyzer`, keep `XAI_API_KEY` in `.env`.
2. Deploy the Worker (opens a Cloudflare login in the browser the first time):

   ```powershell
   cd C:\Users\tgkoe\powerlynq-synergy-analyzer
   .\scripts\deploy-worker.ps1
   ```

3. Copy the printed `*.workers.dev` URL into `analyzer/api-config.js`:

   ```js
   window.__POWERLYNQ_SYNERGY_API__ = "https://powerlynq-synergy.<subdomain>.workers.dev";
   ```

4. Rebuild/copy if the UI changed:

   ```powershell
   cd C:\Users\tgkoe\powerlynq-synergy-analyzer
   .\scripts\publish-to-site.ps1
   ```

5. Commit and push this repo (`deploy.ps1` or `git push`).

**First Grok email:** if Resend is not configured, the Worker uses FormSubmit. Check `engage@powerlynq.com` and confirm the activation message so later intakes land in the inbox.

**Optional Namecheap (after Worker exists):** CNAME `api` → the `workers.dev` host, then point `api-config.js` at `https://api.powerlynq.com`. Apex/`www` stay on GitHub Pages.

After DNS propagates (often 15–60 minutes, sometimes up to 24–48h):

1. GitHub repo → **Settings → Pages**
2. Confirm custom domain `powerlynq.com`
3. Enable **Enforce HTTPS** (may take a few minutes after DNS verifies)

---

## Useful URLs

- Temporary: `https://<username>.github.io/<repo>/` (if project site) or `https://<username>.github.io/` (if username.github.io repo)
- Custom: `https://powerlynq.com` (after DNS)
