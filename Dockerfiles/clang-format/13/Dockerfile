FROM registry.hub.docker.com/library/debian:bullseye-slim
LABEL Description="Image with clang-format 13"
WORKDIR /work

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      git \
      python3-pip \
      && \
    apt-get clean && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/*

# For some weird reason, the clang-format-13 debian package does not
# obey the formating in the .clang-format, so we need to install
# clang-format with pip
RUN pip3 install clang-format==13.0.0

COPY Dockerfile Dockerfile
