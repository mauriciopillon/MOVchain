# Use Go base image for building
FROM golang:1.19-alpine AS builder

# Set working directory
WORKDIR /app

# Copy go mod files first (for better caching)
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the chaincode
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o chaincode .

# Use a minimal base image for the final stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/chaincode .

# Expose the chaincode port
EXPOSE 7052

# Run the chaincode
CMD ["./chaincode"]
