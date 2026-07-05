FROM golang:1.24-alpine AS build

WORKDIR /src
COPY . .
RUN go build -o /quicknotes .

FROM alpine:3.22

WORKDIR /app
COPY --from=build /quicknotes /app/quicknotes
COPY seed.json /app/seed.json

EXPOSE 8080
CMD ["./quicknotes"]
