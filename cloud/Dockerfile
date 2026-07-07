# syntax=docker/dockerfile:1
# Hugging Face Space (Docker SDK) for QuickNotes — builds from source.
# The Space repo also holds the app source (go.mod, *.go, seed.json copied from
# ../app), so `COPY . .` picks it up. Building in the Space keeps it self-contained
# and avoids needing the ghcr package public first (see design question f).
FROM golang:1.24 AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /qn .

FROM gcr.io/distroless/static:nonroot
COPY --from=build /qn /qn
COPY --from=build /src/seed.json /seed.json
# HF gives no writable named volume and runs an arbitrary UID → notes to /tmp.
ENV ADDR=":8080" \
    DATA_PATH="/tmp/notes.json" \
    SEED_PATH="/seed.json"
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/qn"]
