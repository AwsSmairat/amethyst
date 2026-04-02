# Deploying on Render

## Environment variables (required)

- **`DATABASE_URL`** — PostgreSQL connection string from Render Postgres (or external DB). Use the **Internal** URL when the web service and DB are both on Render.
- **`JWT_SECRET`** — long random string (required for signing tokens in production).

Optional:

- **`NODE_ENV`** — `production`
- **`CORS_ORIGIN`** — your Flutter/web origins if not using `*`

## Build & start

The `package.json` **build** script runs:

1. `prisma generate`
2. `prisma migrate deploy` (creates/updates tables)
3. `prisma db seed` (default users — idempotent; skips existing emails)

So you do **not** need to run seed manually on Render unless you change seed data and want to re-run.

**Start** runs `node src/server.js` (listens on `process.env.PORT`).

## Seeded test users

After a successful build, you can log in with (password `123456` for all): `super@test.com` (super_admin), `admin@test.com` (admin), `driver@test.com` (driver). See `prisma/seed.js`.

To seed again by hand (optional):

```bash
npx prisma db seed
```

## If login shows “Internal server error” or database errors

1. **Render logs** — open the service → **Logs** and look for Prisma or connection errors.
2. **`DATABASE_URL`** — must be reachable from the web service (firewall, SSL, correct host).
3. **Migrations** — confirm the build step completed (`prisma migrate deploy`) without errors.
4. **Seed** — check build logs for `prisma db seed`; it runs automatically after migrations. Run `npx prisma db seed` manually only if needed.

## Health checks

- `GET https://<your-service>.onrender.com/` — basic JSON
- `GET https://<your-service>.onrender.com/health` — health
- `GET https://<your-service>.onrender.com/api/health` — API health
