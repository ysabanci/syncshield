#!/usr/bin/env python3

import socket
import os
import json
from datetime import datetime, timezone

NODE_NAME = os.environ.get("NODE_NAME", "unknown")
LISTEN_PORT = 2222
LOG_DIR = "/var/sync_intel"
SSH_BANNER = b"SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.1\r\n"


def log_attempt(remote_ip: str, remote_port: int, data: bytes) -> None:
    timestamp = datetime.now(timezone.utc).isoformat()
    entry = {
        "timestamp": timestamp,
        "node": NODE_NAME,
        "event": "ssh_honeypot_connection",
        "source_ip": remote_ip,
        "source_port": remote_port,
        "raw_payload": data.decode("utf-8", errors="replace")[:512],
    }

    log_file = os.path.join(LOG_DIR, f"honeypot_{NODE_NAME}.jsonl")
    with open(log_file, "a") as f:
        f.write(json.dumps(entry) + "\n")

    print(f"[HONEYPOT][{NODE_NAME}] {timestamp} – Bağlantı: {remote_ip}:{remote_port}")


def main() -> None:
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", LISTEN_PORT))
    server.listen(5)
    print(f"[HONEYPOT][{NODE_NAME}] Port {LISTEN_PORT} üzerinde dinleniyor...")

    while True:
        try:
            client_sock, (remote_ip, remote_port) = server.accept()
            client_sock.sendall(SSH_BANNER)

            client_sock.settimeout(5.0)
            try:
                data = client_sock.recv(1024)
            except socket.timeout:
                data = b""

            log_attempt(remote_ip, remote_port, data)
            client_sock.close()

        except Exception as e:
            print(f"[HONEYPOT][{NODE_NAME}] Hata: {e}")


if __name__ == "__main__":
    main()
