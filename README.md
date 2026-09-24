# TradeVault — Full Startup Architecture

This package is the next architecture layer for TradeVault:
- Public SaaS landing page
- Product sections, pricing, FAQ and About
- Login / sign up / forgot password / reset password UI
- Full signup fields: first name, middle name, surname, email, phone, password
- Light + dark modes
- Authenticated private dashboard
- Overview / Trades / Analytics / Risk / Psychology / Playbook / Journal / Settings
- Supabase cloud schema with RLS
- User profiles
- Trading accounts
- Trades
- Journals
- Playbook entries
- Subscription state
- Coupon redemption table for future premium rollout
- Private screenshot storage bucket
- JSON backup export

## Important
This is the production starter architecture, not the final payment/integration layer.

Do NOT put a Supabase `service_role` key in the browser. Only the project URL and anon/public key belong in a frontend.

## 1. Supabase
1. Create a Supabase project.
2. Open SQL Editor.
3. Paste the complete contents of `supabase.sql`.
4. Run it.
5. Go to Project Settings → API.
6. Copy the Project URL and anon/public key.

## 2. Connect TradeVault
Open `index.html` in a browser after deployment. The current frontend expects the Supabase client configuration to be supplied through the next configuration step.

For a public GitHub Pages build, a better production approach is to put the public URL/key into a tiny config file or environment-aware build. The anon key is safe to expose when RLS is correctly configured; the service-role key is never safe to expose.

## 3. GitHub Pages
Put:
- index.html
- styles.css
- app.js
- supabase.sql
- README.md

in the repository root. Enable Pages from `main` / `(root)`.

## 4. Authentication settings
In Supabase Authentication:
- Configure your site URL to your GitHub Pages URL.
- Add the same URL to Redirect URLs.
- Enable email/password.
- Configure SMTP before relying on production email verification/password reset.
- Google OAuth can be enabled later by adding Google credentials.

## 5. Product roadmap
### Launch
- Free journal
- Core analytics
- Risk tools
- Playbook
- Responsive UI
- Cloud account

### Premium phase
- Advanced analytics
- Backtesting
- Trade replay
- Broker / prop firm sync
- AI-assisted review
- Advanced exports
- Multiple workspaces

### Payments
Do payments through a payment provider's hosted/secure checkout. Do not store card numbers or crypto private keys in TradeVault.

The subscription table is intentionally present now so payment state can be connected later.

## 6. Recommended production stack
Frontend: TradeVault web app
Auth + DB: Supabase
Hosting: GitHub Pages initially, then a proper app host if server-side routes are needed
Payments: provider-hosted checkout + webhook backend
Analytics: product analytics with privacy controls
Email: transactional email provider
Error monitoring: application error monitoring

## 7. Before public launch
- Verify RLS with two separate test accounts.
- Test signup, email verification, login and reset password.
- Test that User A cannot read User B's trades.
- Add Privacy Policy, Terms and Risk Disclosure.
- Add contact/support email.
- Configure backups.
- Add rate limits / abuse protection where appropriate.
- Test mobile Safari and Android Chrome.
- Do not promise financial results.
