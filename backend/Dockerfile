# Build Stage
FROM golang:1.25.2-alpine AS builder

WORKDIR /app

# Install git for fetching dependencies
RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./main.go

# Production Stage
FROM alpine:latest

WORKDIR /app

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

COPY --from=builder /app/main .
COPY --from=builder /app/.env . 

# Expose port
EXPOSE 8080

CMD ["./main"]
