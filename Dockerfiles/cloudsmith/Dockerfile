FROM python:3.12.2-slim-bookworm

LABEL Description="Image with Cloudsmith CLI tool"

ENV PIP_REQUEREMENTS \
  cloudsmith-cli 

# install any python requirements
RUN pip3 install ${PIP_REQUEREMENTS}
