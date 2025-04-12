# 1.2.9-alpine
FROM oven/bun@sha256:395f8524ee2eaad681a70846afdc63afa7f57e8f8e91935e12106c5daab592c0 AS builder
RUN addgroup -g 10001 \
             -S nonroot \
    && adduser -G nonroot \
               -h /home/nonroot \
               -S \
               -u 10000 nonroot
USER nonroot:nonroot
WORKDIR /home/nonroot

COPY --chmod=0644 \
     --chown=nonroot:nonroot ./bun.lock \
                             ./package.json ./nayud/
RUN bun i --cwd ./nayud \
          --frozen-lockfile \
          --production

COPY --chmod=0755 \
     --chown=nonroot:nonroot . ./nayud
RUN bun run --cwd ./nayud build

# 1.27.4-alpine3.21
FROM nginxinc/nginx-unprivileged@sha256:d43566af1caeaf6d16d4880f587cdeb9e0efe172aad1d1d43ca4ce0fa304e293
USER root:root
RUN addgroup -g 10001 \
             -S nonroot \
    && adduser -G nonroot \
               -h /home/nonroot \
               -S \
               -u 10000 nonroot
USER nonroot:nonroot

EXPOSE 8080
STOPSIGNAL SIGQUIT

ARG TINI_VERSION=v0.19.0
ADD --chmod=0755 \
    --chown=nonroot:nonroot https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static \
                            /tini
ENTRYPOINT ["/tini", "--"]

COPY --from=builder \
     --chmod=0755 \
     --chown=nonroot:nonroot /home/nonroot/nayud/build \
                             /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]