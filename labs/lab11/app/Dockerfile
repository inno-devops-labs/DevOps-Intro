FROM golang:1.22
WORKDIR /app
COPY go.mod main.go ./
RUN go build -o app .
CMD ["/app/app"]
