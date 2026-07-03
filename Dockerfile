# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

# Production stage
FROM alpine:3.19

RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    unzip \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

WORKDIR /app

ARG PB_VERSION=0.22.18
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ && rm /tmp/pb.zip

COPY --from=builder /app .

RUN chown -R appuser:appgroup /app

USER appuser

ENV PB_DIR="/app/pb_data"
ENV PB_HTTP="0.0.0.0:8090"

RUN mkdir -p ${PB_DIR} && chown -R appuser:appgroup ${PB_DIR}

EXPOSE 8090

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8090/ || exit 1

CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8090"]
