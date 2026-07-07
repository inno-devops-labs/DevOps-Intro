FROM golang:1.26.4 AS build

RUN useradd -u 65532 nonroot

WORKDIR /build
COPY go.mod ./
RUN go mod download
COPY *.go ./

RUN mkdir -p /rootfs/app
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags='-s -w' -trimpath -o /rootfs/app/qn-bin
RUN mkdir -p /rootfs/data
RUN mkdir -p /rootfs/bin
COPY --from=ghcr.io/tarampampam/microcheck:1.4.0 /bin/httpcheck /rootfs/bin/httpcheck
COPY seed.json /rootfs/app/

FROM scratch

COPY --from=build /etc/passwd /etc/passwd
COPY --from=build --chown=nonroot:root /rootfs/ /

WORKDIR /app
ENV DATA_PATH=/data/notes.json
USER nonroot
EXPOSE 8080
ENTRYPOINT [ "/app/qn-bin" ]
