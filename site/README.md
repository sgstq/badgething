# badgething.app

The landing page for BadgeThing, served by Cloudflare Workers static assets at https://badgething.app.

- `public/` is the site. It is plain HTML and CSS with no build step.
- `wrangler.jsonc` binds the Worker to the `badgething.app` and `www.badgething.app` custom domains.
- `.github/workflows/site.yml` deploys on every push to `main` that touches this directory.

## Deploy

From CI, set the repository secrets `CLOUDFLARE_API_TOKEN` (Workers Scripts: Edit, Workers Routes: Edit, Zone DNS: Edit on badgething.app) and `CLOUDFLARE_ACCOUNT_ID`. The `badgething.app` zone must already be on the Cloudflare account.

By hand:

```bash
cd site
npm install
npx wrangler login     # or export CLOUDFLARE_API_TOKEN=...
npm run deploy
```
