# Lumen API

Backend API for Lumen — a concert-logging app ("Strava for music"). Built with Ruby on Rails, PostgreSQL, and S3 for media storage.

---

## For frontend developers

You don't need to know Ruby or Rails. You just need Docker.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- A `.env` file (get this from Oliver — do not commit it)

### First-time setup

```bash
# 1. Clone the repo
git clone git@github.com:Djursing/lumen.git
cd lumen

# 2. Place the .env file Oliver sent you in the root of the project
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
| LocalStack | http://localhost:4566            | Local S3 (media file storage)   |
| Postgres   | localhost:5432                   | Database (internal use only)    |

### Verifying it works

```bash
curl http://localhost:3000/up
# → "OK"
```

### Demo accounts

The database is pre-seeded with two accounts and several concerts each. Use these to log in straight away:

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

## Pulling in new changes

```bash
git pull
docker compose up --build   # rebuild picks up any new gems or migrations
```

The entrypoint automatically runs database migrations on startup, so you never need to run them manually.

---

## Environment variables

The `.env` file Oliver provides contains everything needed. See `.env.example` in the repo for the full list of variables and what they do. Never commit your `.env` file — it's gitignored.
