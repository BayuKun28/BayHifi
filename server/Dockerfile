# Stage 1: Build Go binary
FROM golang:1.24-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git ca-certificates

COPY go.mod ./
COPY . .

ENV GOTOOLCHAIN=auto
ENV GOSUMDB=off
ENV GOPROXY=https://proxy.golang.org,direct

RUN go get github.com/dhowden/tag@master || go get github.com/dhowden/tag
RUN go get github.com/golang-jwt/jwt/v5@v5.2.1
RUN go get golang.org/x/crypto@v0.32.0
RUN go get modernc.org/sqlite@v1.34.4
RUN go mod tidy -e || true
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o bayhifi-service .

# Stage 2: Ultra-minimal Alpine runtime (~15MB image)
FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app
COPY --from=builder /app/bayhifi-service /app/bayhifi-service

RUN mkdir -p /data

EXPOSE 8081

ENTRYPOINT ["/app/bayhifi-service"]
