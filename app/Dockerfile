FROM golang:1.24-alpine AS builder

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /quicknotes .

RUN printf 'package main\nimport("net/http"\n"os")\nfunc main(){r,e:=http.Get("http://localhost:8080/health")\nif e!=nil||r.StatusCode!=200{os.Exit(1)}}' > /tmp/hc.go && \
    CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /healthcheck /tmp/hc.go

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY seed.json /seed.json

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
