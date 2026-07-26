# Google Analytics 4 setup for powerlynq.com

## 1. Create a GA4 property (about 5 minutes)

1. Open [Google Analytics](https://analytics.google.com/) and sign in with your Google account.
2. If prompted, click **Start measuring** / **Admin** (gear, bottom left).
3. **Create Account** (if you have none):
   - Account name: e.g. `PowerlynQ`
   - Accept defaults / data sharing as you prefer → **Next**
4. **Create Property**:
   - Property name: `PowerlynQ Website`
   - Reporting time zone: your zone (e.g. United States – Pacific)
   - Currency: USD → **Next**
5. Business details: pick what fits (e.g. Business size, industry) → **Create** / accept terms.
6. **Data collection – Web**:
   - Website URL: `https://powerlynq.com`
   - Stream name: `powerlynq.com`
   - **Create stream**
7. On the stream details page, copy the **Measurement ID**  
   It looks like: **`G-XXXXXXXXXX`**

## 2. Tell PowerlynQ (or set it yourself)

### Option A — send the ID here  
Reply with your `G-…` ID and it will be put in the site and deployed.

### Option B — set it yourself  
1. Open `analytics-config.js` in this folder.
2. Set:

```js
window.POWERLYNQ_GA_ID = "G-XXXXXXXXXX";
```

3. Deploy:

```powershell
cd C:\Users\tgkoe\powerlynq-site
git add analytics-config.js analytics.js index.html
git commit -m "Enable Google Analytics 4"
git push origin main
```

## 3. Verify it works

1. Wait 1–2 minutes after deploy, hard-refresh https://powerlynq.com
2. In GA: **Reports → Realtime** (left menu)
3. Open the site in another tab — you should see **1 user** (or more) in Realtime within ~30 seconds.

Optional: Chrome extension **Google Analytics Debugger**, or DevTools → Network → filter `google-analytics` / `gtag` / `collect`.

## Notes

- GA4 is free for this use case.
- IP anonymization is enabled in `analytics.js`.
- No tracking runs until a real `G-` ID is set in `analytics-config.js`.
- For a privacy notice later, you can state that the site uses Google Analytics to understand traffic.
