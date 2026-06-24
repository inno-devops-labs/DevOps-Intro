# ===== СТЕЙДЖ 1: СБОРКА =====
FROM golang:1.24-alpine AS builder

WORKDIR /build

# Кешируем зависимости
COPY go.mod go.sum ./
RUN go mod download

# Копируем исходники
COPY . .

# Собираем статический бинарник
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-s -w' \
    -trimpath \
    -o quicknotes .

# ===== СТЕЙДЖ 2: РАНТАЙМ =====
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /build/quicknotes .

COPY --from=busybox:stable-musl /bin/busybox /bin/busybox

# Создаём каталог /data и даём права пользователю 65532
USER root
RUN ["/bin/busybox", "mkdir", "-p", "/data"]
RUN ["/bin/busybox", "chown", "65532:65532", "/data"]
USER 65532

EXPOSE 8080

ENTRYPOINT ["/app/quicknotes"]