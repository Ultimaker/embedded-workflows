FROM registry.hub.docker.com/library/debian:bookworm-slim
LABEL Description="Image with clang-tidy 14"
WORKDIR /work

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      clang-tidy-14 \
      && \
    apt-get clean && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/* && \
    ln -s /usr/bin/clang-tidy-14 /usr/bin/clang-tidy

COPY Dockerfile Dockerfile
