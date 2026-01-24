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

# Create non-privileged user for security
RUN useradd -m -u 1000 -s /bin/bash builder && \
    chown -R builder:builder /work

USER builder

COPY Dockerfile Dockerfile
