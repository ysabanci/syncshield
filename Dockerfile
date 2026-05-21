FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    inotify-tools \
    iptables \
    ipset \
    curl \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/sync_intel

COPY scripts/ /opt/syncshield/
RUN chmod +x /opt/syncshield/*.sh

COPY .env /opt/syncshield/.env

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /opt/syncshield

ENTRYPOINT ["/entrypoint.sh"]
