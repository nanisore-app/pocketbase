FROM alpine:3.19

RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    unzip

ARG PB_VERSION=0.22.18
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ && rm /tmp/pb.zip

WORKDIR /app
RUN mkdir -p /app/pb_data

EXPOSE 8090

CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8090", "--dir=/app/pb_data"]
