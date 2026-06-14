# Lumen API

Backend API for Lumen — a concert-logging app ("Strava for music"). Built with Ruby on Rails, PostgreSQL, Clerk for authentication, and Cloudflare R2 for media storage.

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

# 2. Place the .env file in the root of the project
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

### Authentication

This API uses [Clerk](https://clerk.com) for authentication. There are no login/register endpoints — authentication is handled entirely by Clerk on the frontend.

To make authenticated requests locally:

1. Sign in via the frontend app to get a Clerk session
2. Retrieve your session token from the Clerk dashboard or via `clerk.session.getToken()` in the browser console
3. Pass it as a Bearer token:

```bash
curl -s http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer <your-clerk-token>"
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

1. Retrieve a Clerk token (see Authentication section above)
2. Click the **Authorize** button (top right of Swagger UI)
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

In local development, file uploads go to **LocalStack** — a local emulator of AWS S3. There is no real S3 bucket involved; everything stays on your machine.

When you upload a file via `POST /api/v1/events/:id/media`, the API normalizes it (resizes to max 3000×3000px, converts to JPEG) and returns the new media record:

```json
{
  "id": 1,
  "url": "http://localhost:4567/lumen-media/...",
  "thumbnail_url": "http://localhost:4567/lumen-media/...",
  "created_at": "2026-05-24T12:00:00.000Z"
}
```

Fetching all media for an event via `GET /api/v1/events/:id/media` returns:

```json
{
  "items": [ { "id": 1, "url": "...", "thumbnail_url": "...", "created_at": "..." } ],
  "limit": 10,
  "remaining": 9
}
```

Each event can hold a maximum of **10 photos**. Uploading when the limit is reached returns `422`.

URLs are time-limited presigned links (6 days). In development they point to `localhost:4567`.

> **Note:** LocalStack data is stored in a Docker volume. It persists across restarts but is wiped when you run `docker compose down -v`.

---

## Pulling in new changes

```bash
git pull
docker compose up --build
```

The entrypoint automatically runs database migrations on startup.

---

## Live code reloading

The app container mounts the source code directly from your machine. Edits to `.rb` files are picked up on the next request — no restart or rebuild required.

---

## Environment variables

See `.env.example` for the full list. Never commit your `.env` file — it's gitignored.

Key variables:

| Variable | Description |
|----------|-------------|
| `CLERK_SECRET_KEY` | Clerk secret key (`sk_test_...` for dev, `sk_live_...` for prod) |
| `ALLOWED_ORIGINS` | Comma-separated list of allowed frontend origins (production only) |
| `AWS_ACCESS_KEY_ID` | R2 access key |
| `AWS_SECRET_ACCESS_KEY` | R2 secret key |
| `S3_BUCKET_NAME` | R2 bucket name |
| `S3_ENDPOINT` | R2 endpoint URL |

---

## Production deployment (Railway)

The app is deployed on [Railway](https://railway.app) with three services: Rails API, Postgres, and the frontend.

### Rails API service environment variables

```
CLERK_SECRET_KEY=sk_live_...
ALLOWED_ORIGINS=https://your-frontend.up.railway.app
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=auto
S3_BUCKET_NAME=lumen-media
S3_ENDPOINT=https://<account_id>.r2.cloudflarestorage.com
S3_FORCE_PATH_STYLE=true
DATABASE_URL=<set automatically by Railway Postgres>
SECRET_KEY_BASE=<openssl rand -hex 64>
WEB_CONCURRENCY=1
```

### Deploys

Railway deploys automatically on push to `main`.
