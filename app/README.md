# QuickNotes

A tiny notes API in Go — the course-wide project for DevOps-Intro.

You will not modify this code (much). Across 10 labs you will **package, ship, deploy, observe, secure, and host it.**

## Run it

```bash
cd app/
go run .
# in another terminal:
curl http://localhost:8080/health
curl http://localhost:8080/notes
curl -X POST http://localhost:8080/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"first","body":"hello"}'
```

## Endpoints

| Method | Path           | Returns |
|--------|----------------|---------|
| GET    | `/health`      | `{ "status": "ok", "notes": N }` |
| GET    | `/metrics`     | Prometheus text format |
| GET    | `/notes`       | `[]Note` |
| GET    | `/notes/{id}`  | `Note` or 404 |
| POST   | `/notes`       | created `Note` (201) |
| DELETE | `/notes/{id}`  | 204 or 404 |

## Configuration

| Env       | Default            | Notes |
|-----------|--------------------|-------|
| `ADDR`    | `:8080`            | Listen address |
| `DATA_PATH` | `data/notes.json` | Persistent state file |
| `SEED_PATH` | `seed.json`       | Seed data on first boot |

## Tests

```bash
make test
# or: go test ./...
```

## Versioning

Releases are tagged `vMAJOR.MINOR.PATCH`. `v0.0.1` is the first tagged build.
