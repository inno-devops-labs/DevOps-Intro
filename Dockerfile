FROM golang:1.24.13 AS build

RUN groupadd -r appgroup && useradd -r -g appgroup -u 65532 nonroot

WORKDIR /app

COPY --chown=nonroot:appgroup app /app/

RUN go mod download

RUN CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o /bin/qn .

FROM scratch

COPY --from=build /bin/qn /bin/qn

USER 65532

EXPOSE 8080

ENTRYPOINT ["/bin/qn"]
