# NAZU Testnet — real backend / future-airdrop-ready build

This project is a real server-verified participation system designed to support a future points-based reward/airdrop program. It is **not** a blockchain validator and it does not create or transfer tokens today.

## What is real
- EVM wallet ownership verification by signed challenge (no transaction).
- Sepolia testnet network check by default.
- Server-side session tokens stored as hashes.
- Server-side heartbeat acceptance, rate limiting and uptime accounting.
- Persistent points and user records in Postgres/Supabase.
- Admin wallet allowlist and signed admin access.
- RLS enabled; browser never receives the Supabase secret key.
- Airdrop allocation/snapshot tables are prepared for a future reward event.

## Important security rule
The browser uses only the **publishable key**. Supabase's current guidance says publishable keys are suitable for public clients when RLS is configured, while secret keys bypass RLS and must stay on the backend. Supabase is also moving from legacy `anon`/`service_role` names to `sb_publishable_...` / `sb_secret_...`.

Never paste a `sb_secret_...` key or legacy `service_role` key into `config.js`, GitHub, or a browser.

## Supabase setup
1. Create a Supabase project.
2. Run `supabase-schema.sql` in SQL Editor.
3. Create a **publishable** key for the frontend.
4. Deploy the Edge Functions.
5. Configure backend secrets: `SUPABASE_SECRET_KEY` and `ADMIN_WALLETS`.
6. Optional: set `ELIGIBILITY_POINTS`.
7. Put the public project URL + publishable key into `config.js`.

Example backend secrets:
- `SUPABASE_SECRET_KEY=sb_secret_...`
- `ADMIN_WALLETS=0xyouradminwallet`
- `ELIGIBILITY_POINTS=1000`

If your project still uses legacy keys, `SUPABASE_SERVICE_ROLE_KEY` remains supported as a fallback in the shared function code, but new deployments should use the secret key.

## Deploy
```bash
supabase db push
supabase functions deploy challenge --no-verify-jwt
supabase functions deploy verify --no-verify-jwt
supabase functions deploy heartbeat --no-verify-jwt
supabase functions deploy stop --no-verify-jwt
supabase functions deploy me --no-verify-jwt
supabase functions deploy admin-stats --no-verify-jwt
supabase functions deploy admin-users --no-verify-jwt
```

Host the static files (`index.html`, `admin.html`, `config.js`) on your preferred HTTPS static host.

## Points / anti-abuse
- First accepted heartbeat: 1 point.
- Later heartbeats: points are based on server-measured elapsed minutes, capped at 2 points per accepted heartbeat.
- Heartbeats faster than 20 seconds are rejected.
- Uptime credited per heartbeat is capped at 90 seconds.
- Eligibility is server-controlled.

This is deliberately not marketed as “guaranteed free money”. Participation points can be used as an input to a future reward policy, but an airdrop is only real after the project publishes final eligibility rules, snapshot date, token allocation, claim mechanism, and any applicable legal/compliance requirements.

## Future airdrop architecture
The database already contains `airdrop_allocations` and `reward_config`. A later release can:
1. freeze a points snapshot;
2. apply published eligibility/Sybil rules;
3. calculate each wallet's allocation;
4. publish a Merkle root or equivalent claim dataset;
5. deploy/verify the token contract if a token is actually launched;
6. let eligible users claim through a separately audited claim contract.

Do **not** promise a token amount before those rules are finalized.
