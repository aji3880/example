FROM golang:1.24 AS builder
WORKDIR /app

COPY app/ .

RUN go mod init contoh || true \
    && go mod tidy

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server main.go

FROM gcr.io/distroless/base-debian12:nonroot
WORKDIR /app

COPY --from=builder /app/server .
COPY --from=builder /app/templates ./templates
COPY --from=builder /app/static ./static

USER user
EXPOSE 8080
ENTRYPOINT ["/app/server"]
