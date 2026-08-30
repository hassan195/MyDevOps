# RUNBOOK: inventory-api won't start

If you're reading this at 2am, don't think — just go through these in order.
Stop at the first one that fixes it.

---

## 1. Is inventory-db actually healthy?

inventory-api depends on inventory-db being *healthy*, not just running.
This is the #1 cause of "won't start" — Postgres takes a few extra seconds
under load, and depends_on won't let inventory-api past that gate.

```bash
docker compose ps
```

Look at the STATUS column for `inventory-db`. You want to see `healthy`.
If it says `starting` — wait 10s and check again, it's probably still coming up.
If it says `unhealthy` — go to step 2.

If inventory-db is healthy but inventory-api is still not starting,
skip to step 4.

---

## 2. Is Postgres actually accepting connections?

```bash
docker compose exec inventory-db pg_isready -U inventory -d inventory
```

Expected output: `accepting connections`

If you get `no response` or `connection refused`:
- Check disk space on the host — Postgres silently fails to start on a full disk:
```bash
  df -h
```
- Check for a corrupted data directory (rare, usually only after an
  unclean shutdown or manually deleting files under the volume):
```bash
  docker compose logs inventory-db --tail=50
```
  Look for lines mentioning `PANIC`, `FATAL`, or `could not read`.

---

## 3. Did .env actually get loaded?

Missing or empty `.env` is the #2 cause — someone pulled the repo fresh
and forgot `.env` isn't in git (by design, see AC-4).

```bash
cat .env
```

If this file doesn't exist or is empty:
```bash
cp .env.example .env
# then fill in real values before continuing
```

Confirm the values actually made it into the container:
```bash
docker compose exec inventory-db env | grep POSTGRES
```

If these are blank inside the container even though `.env` looks fine,
check `env_file:` in compose.yaml points to the right path.

---

## 4. Check inventory-api's own logs

```bash
docker compose logs inventory-api --tail=100
```

Every log line should have a timestamp — if you see bare unstamped lines,
that's a separate bug (already tracked), not this incident. Focus on the
last few lines before the crash.

Common patterns to look for:

| Log contains | Likely cause | Next step |
|---|---|---|
| `Connection refused` / `could not connect to server` | inventory-db wasn't ready when inventory-api first tried | Go back to step 1–2 |
| `password authentication failed` | `.env` password doesn't match what Postgres was seeded with | Go to step 5 |
| `Address already in use` | Port conflict on the host | Go to step 6 |
| `ModuleNotFoundError` / `ImportError` | Image is stale, missing a dependency | Go to step 7 |

---

## 5. Password mismatch (only if inventory-db was ever restarted with a *different* .env)

Postgres only reads `POSTGRES_PASSWORD` on **first initialization** of the
volume. If someone changed `.env` after the volume already existed,
Postgres is still running with the *old* password, and inventory-api is
trying to connect with the *new* one from `.env` — they disagree.

Check when the volume was created vs when `.env` was last changed:
```bash
docker volume inspect <project>_inventory-db-data | grep CreatedAt
```

If `.env` was edited more recently than the volume was created, you have
two options:
- Re-seed cleanly (⚠️ destroys current data): `docker compose down -v && docker compose up -d`
- Or fix `.env` back to match the password Postgres was actually initialized with

---

## 6. Port already in use

```bash
docker compose logs inventory-api | grep "Address already in use"
```

Something else on the host is squatting on the port. Find and stop it:
```bash
lsof -i :8080   # replace with whatever port inventory-api binds to
```

If it's a stale container from a previous `docker compose up` that didn't
get cleaned up:
```bash
docker compose down
docker compose up -d
```

---

## 7. Stale image / dependency drift

If none of the above match, the image itself may be out of date relative
to the code:

```bash
docker compose build inventory-api --no-cache
docker compose up -d inventory-api
```

---

## If you're still stuck after all 7 steps

Escalate — don't keep guessing. Post in #inventory-oncall with:
1. Output of `docker compose ps`
2. Output of `docker compose logs inventory-api --tail=100`
3. Which step above you got stuck on