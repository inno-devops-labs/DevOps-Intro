# Hugging Face Space Deployment

Target Space:

- Hugging Face repo: `https://huggingface.co/spaces/Axxilius/quicknotes`
- Expected app URL: `https://axxilius-quicknotes.hf.space`

## What to do manually

1. In Hugging Face, open the existing Space `Axxilius/quicknotes` and confirm it is `Public` and uses the `Docker` SDK.
2. Clone the Space repository locally.
3. Copy `cloud/hf-space/Dockerfile` to the root of the Space repository as `Dockerfile`.
4. Copy `cloud/hf-space/README.md` to the root of the Space repository as `README.md`.
5. Commit and push the changes to the Space repository.
6. Wait for the Space build to finish and confirm the status becomes healthy.
7. Verify the API:

```bash
curl -v https://axxilius-quicknotes.hf.space/health
curl -v https://axxilius-quicknotes.hf.space/notes
```

## Warm latency

Run this after the Space is already awake:

```bash
for i in 1 2 3 4 5; do curl -w '%{time_total}\n' -o /dev/null -s https://axxilius-quicknotes.hf.space/health; done
```

Record the five values. I will compute the warm `p50` and put it into `submissions/lab10.md`.

## Cold latency

After at least 35 minutes of inactivity, run this once:

```bash
curl -w '%{time_total}\n' -o /dev/null -s https://axxilius-quicknotes.hf.space/health
```

Repeat that cold measurement three times, each time allowing the Space to go back to sleep first.

## Send me back

Send me these outputs and I will finish Task 2 in the submission:

1. The final public Space URL.
2. The `curl -v` output for `/health`.
3. The five warm latency values.
4. The three cold latency values.
5. Any build failure log, if the Space does not come up cleanly.

## Why this design

This Space pulls the immutable `v0.1.1` image instead of rebuilding QuickNotes from source. That keeps deployment aligned with the release artifact already published in Task 1, improves reproducibility, and makes debugging cleaner because the Space is running the exact image we already verified with `docker pull`.