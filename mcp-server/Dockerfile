FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy root go.mod if it exists, otherwise just mcp-server/go.mod
COPY go.mod ./
# RUN go mod download # Skip if no dependencies or go.sum

COPY . .

RUN go build -o mcp-server ./cmd/mcp

FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/mcp-server .
COPY manifest.json .

# Cloud Run default port
EXPOSE 8080

CMD ["./mcp-server", "serve", "-addr", ":8080"]
