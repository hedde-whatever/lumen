# Lumen API

Backend API for Lumen — a concert-logging app ("Strava for music"). Built with Ruby on Rails, PostgreSQL, and S3 for media storage.

---

## For frontend developers

You don't need to know Ruby or Rails. You just need Docker.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- A `.env` file (get this from someone in the team — do not commit it)

### First-time setup

```bash
# 1. Clone the repo
git clone git@github.com:Djursing/lumen.git
cd lumen

# 2. Place the .env file sent you in the root of the project
#    It should sit next to docker-compose.yml

# 3. Build and start everything
docker compose up --build
```

That's it. The first build takes a few minutes as it installs dependencies. On subsequent runs just use `docker compose up`.

### What starts

| Service    | URL                              | Description                     |
|------------|----------------------------------|---------------------------------|
| Rails API  | http://localhost:3000            | The API                         |
| Swagger UI | http://localhost:3000/api-docs   | Interactive API docs             |
| LocalStack | http://localhost:4567            | Local S3 (media file storage)   |
| Postgres   | localhost:5432                   | Database (internal use only)    |

### Verifying it works

```bash
curl http://localhost:3000/up
# → "OK"
```

### Demo accounts

The database is pre-seeded with two accounts, several concerts each, and 2 photos per concert already uploaded to LocalStack. Use these to log in straight away:

| Email | Password |
|-------|----------|
| alice@lumen.dev | password123 |
| bob@lumen.dev | password123 |

```bash
curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@lumen.dev","password":"password123"}' | jq .token
```

### Stopping

```bash
docker compose down
```

To also wipe the database and S3 storage volumes (full reset):

```bash
docker compose down -v
```

---

## API documentation

Open **http://localhost:3000/api-docs** in your browser once the stack is running.

You'll see all available endpoints with full request/response contracts. To try authenticated endpoints:

1. Call `POST /api/v1/auth/register` or `POST /api/v1/auth/login` to get a token
2. Click the **Authorize** button (top right of the Swagger UI)
3. Paste the token and click Authorize
4. All subsequent requests in the UI will include the Bearer token

---

## API base URL

```
http://localhost:3000/api/v1
```

All endpoints (except `/up`) live under `/api/v1/`.

---

## Media uploads and LocalStack

In local development, file uploads (concert photos/videos) go to **LocalStack** — a local emulator of AWS S3. There is no real S3 bucket involved; everything stays on your machine.

When you upload a file via `POST /api/v1/events/:id/media`, the API stores it in LocalStack and returns the new media record:

```json
{
  "id": 1,
  "path": "uploads/users/1/events/3/uuid-photo.jpg",
  "url": "http://localhost:4567/lumen-media/uploads/users/1/events/3/uuid-photo.jpg?...",
  "created_at": "2026-05-24T12:00:00.000Z"
}
```

Fetching all media for an event via `GET /api/v1/events/:id/media` returns an envelope with the limit built in — use this to decide whether to show the upload button:

```json
{
  "items": [ { "id": 1, "path": "...", "url": "...", "created_at": "..." } ],
  "limit": 10,
  "remaining": 9
}
```

Each event can hold a maximum of **10 photos**. Uploading when the limit is reached returns `422`.

The `url` field is a time-limited link (6 days) that points to `localhost:4567`. You can load it directly in an `<Image>` tag or `fetch()` call — no extra configuration needed.

> **Note:** LocalStack data is stored in a Docker volume. It persists across restarts but is wiped when you run `docker compose down -v`.

---

## Pulling in new changes

```bash
git pull
docker compose up --build   # rebuild picks up any new gems or migrations
```

The entrypoint automatically runs database migrations on startup, so you never need to run them manually.

---

## Live code reloading

The app container mounts the source code directly from your machine. If you're making backend changes yourself, edits to `.rb` files are picked up on the next request — no restart or rebuild required.

---

## Environment variables

The `.env` file Oliver provides contains everything needed. See `.env.example` in the repo for the full list of variables and what they do. Never commit your `.env` file — it's gitignored.

---

## Production deployment (Fly.io + Cloudflare R2)

### First-time setup

**1. Create a Cloudflare R2 bucket**
- Go to [dash.cloudflare.com](https://dash.cloudflare.com) → R2 → Create bucket
- Name it `lumen-media` (or update `S3_BUCKET_NAME` below)
- Note your **Account ID** from the R2 overview page

**2. Create an R2 API token**
- R2 → Manage API Tokens → Create API token
- Permissions: **Object Read & Write** on your bucket

**3. Set Fly secrets**
```bash
fly secrets set \
  AWS_ACCESS_KEY_ID=<r2-access-key-id> \
  AWS_SECRET_ACCESS_KEY=<r2-secret-access-key> \
  AWS_REGION=auto \
  S3_BUCKET_NAME=lumen-media \
  S3_ENDPOINT=https://<account_id>.r2.cloudflarestorage.com \
  S3_FORCE_PATH_STYLE=true \
  DB_HOST=<fly-postgres-host> \
  DB_USERNAME=<db-user> \
  DB_PASSWORD=<db-password> \
  DB_NAME=lumen_production \
  SECRET_KEY_BASE=$(openssl rand -hex 64) \
  JWT_SECRET=$(openssl rand -hex 32) \
  JWT_EXPIRY_HOURS=0.25 \
  ALLOWED_ORIGINS=https://your-frontend-domain.com
```

**4. Deploy**
```bash
fly deploy
```

### Subsequent deploys
```bash
fly deploy
```

Migrations run automatically on startup — same as local dev.
