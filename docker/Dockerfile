# syntax=docker/dockerfile:1
FROM ubuntu:20.04
WORKDIR /app

RUN export DEBIAN_FRONTEND=noninteractive ; apt-get update ; apt-get -y upgrade

RUN apt-get -y install --no-install-recommends ffmpeg jq curl ca-certificates

RUN apt-get clean ; rm -rf /var/lib/apt/lists/*

COPY worker.sh worker.sh

RUN groupadd -g 999 epworker && \
    useradd -r -u 999 -g epworker epworker

RUN chown -R epworker:epworker /app

USER epworker

CMD ["./worker.sh"]
