FROM golang:1.24.13-bookworm AS builder

WORKDIR /src


COPY go.mod ./
RUN go mod download

# Now the source. This is the layer that changes when you edit code.
COPY . .


ENV CGO_ENABLED=0 GOOS=linux
RUN go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

RUN go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./healthcheck


RUN mkdir -p /data && touch /data/.keep && chown -R 65532:65532 /data


FROM gcr.io/distroless/static:nonroot AS runtime

WORKDIR /


COPY --from=builder /out/quicknotes  /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder /src/seed.json   /seed.json
COPY --from=builder --chown=65532:65532 /data /data


ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

USER 65532:65532

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/healthcheck"]

ENTRYPOINT ["/quicknotes"]
