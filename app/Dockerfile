#---------- Builder stage ----------

FROM golang:1.24-alpine AS builder

# WorkDir

WORKDIR /build

# copy go.mod and run

COPY go.mod ./
RUN go mod download

COPY . .


# CGO_ENABLED=0 — disable CGO 
# -ldflags='-s -w' — delete table symbol

RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-s -w' \
    -trimpath \
    -o quicknotes .

# -------------------- Runtime stage --------------------
FROM gcr.io/distroless/static:nonroot

# copy bin from builder-stage

COPY --from=builder /build/quicknotes /quicknotes

# UID 65532 in distroless/static:nonroot

USER 65532:65532

# port
EXPOSE 8080

# exec-form
ENTRYPOINT ["/quicknotes"]