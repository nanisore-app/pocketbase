# Production stage
FROM alpine:3.19

RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    unzip \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

ARG PB_VERSION=0.22.18
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ && rm /tmp/pb.zip

WORKDIR /app

RUN mkdir -p /app/pb_data && chown -R appuser:appgroup /app

COPY --chown=appuser:appgroup pb_schema.json .

USER appuser

ENV PB_HTTP="0.0.0.0:${PORT}"

EXPOSE ${PORT}

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=5 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/ || exit 1

CMD /pb/pocketbase serve --dir=/app/pb_data --http=0.0.0.0:$PORT
