# Render Deployment

## Configuration

- Service: `quicknotes-lab10`
- Source: existing public GHCR image
- Initial image: `ghcr.io/rslwqr/devops-intro/quicknotes:v0.1.0`
- Region: Frankfurt
- Instance type: Free
- Public URL: `https://quicknotes-lab10.onrender.com`
- Health check path: `/health`

## Environment variables

- `PORT=10000`
- `ADDR=:10000`
- `DATA_PATH=/data/notes.json`
- `SEED_PATH=/app/seed.json`

`PORT` and `ADDR` use the same port so that QuickNotes listens on Render's expected port immediately, without a primary-port detection restart.

## Deployment

The initial deployment used the public `v0.1.0` image from GHCR.

Subsequent releases are deployed automatically from GitHub Actions using a Render deploy hook stored in the `RENDER_DEPLOY_HOOK` GitHub Actions secret. The deploy hook itself is not committed to the repository.

A `v0.1.1` tag was used to verify the CI deployment path successfully. The GitHub Actions release workflow completed successfully and triggered a new Render deployment using the `v0.1.1` image.

## Scale-to-zero measurements

Five consecutive warm requests to `/health` were measured:

| Request | Latency |
|---|---:|
| 1 | 0.756575 s |
| 2 | 0.522607 s |
| 3 | 0.545513 s |
| 4 | 0.508955 s |
| 5 | 0.677659 s |

Warm p50: **0.545513 s**.

After allowing the free Render service to remain idle for at least 20 minutes between measurements, three cold-start samples were recorded:

- Cold start 1: `13.084200 s`
- Cold start 2: `14.023523 s`
- Cold start 3: `13.059400 s`

The cold starts are significantly slower because the free Render service spins down when idle and has to start the service again when a new request arrives.

## Persistence test

A test note was created with `POST /notes`:

```json
{
  "id": 5,
  "title": "Lab 10 persistence test",
  "body": "Testing note persistence after Render spin-down"
}
```

After leaving the Render service idle for more than 20 minutes and waking it again, `GET /notes` returned only the four original seed notes. The test note was no longer present.

This demonstrates that the writable local filesystem of the free Render instance is ephemeral. After the instance is replaced or restarted, QuickNotes starts again from `seed.json`. Durable production data should therefore be stored in persistent external storage such as a database rather than in the container filesystem.
