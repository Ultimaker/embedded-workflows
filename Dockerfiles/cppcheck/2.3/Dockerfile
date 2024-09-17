FROM registry.hub.docker.com/library/debian:bullseye-slim
LABEL Description="Image with cppcheck 2.3"
WORKDIR /work

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      cppcheck \
      && \
    apt-get clean && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/*

COPY Dockerfile Dockerfile
