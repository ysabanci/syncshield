#!/usr/bin/env python3

import socket
import os
import sys
from datetime import datetime, timezone

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 2222
BANNED_FILE = "/var/sync_intel/banned_ips.txt"
SSH_BANNER = b"SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.1\r\n"

NODE_NAME = os.environ.get("NODE_NAME", "unknown")


def ensure_dir() -> None:
    os.makedirs(os.path.dirname(BANNED_FILE), exist_ok=True)


def append_banned_ip(ip: str) -> None:
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    line = f"{timestamp}  {ip}\n"
    with open(BANNED_FILE, "a") as f:
        f.write(line)


def main() -> None:
    ensure_dir()

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    try:
        server.bind((LISTEN_HOST, LISTEN_PORT))
    except OSError as e:
        print(f"[HONEYPOT][{NODE_NAME}] Bind hatası ({LISTEN_HOST}:{LISTEN_PORT}): {e}", file=sys.stderr)
        sys.exit(1)

    server.listen(5)
    print(f"[HONEYPOT][{NODE_NAME}] Dinleniyor: {LISTEN_HOST}:{LISTEN_PORT}")

    while True:
        try:
            client, (remote_ip, remote_port) = server.accept()

            try:
                client.sendall(SSH_BANNER)
            except OSError:
                pass

            try:
                client.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            finally:
                client.close()

            append_banned_ip(remote_ip)
            print(f"[HONEYPOT][{NODE_NAME}] Yakalandi: {remote_ip}:{remote_port} -> banned_ips.txt")

        except KeyboardInterrupt:
            print(f"\n[HONEYPOT][{NODE_NAME}] Kapatılıyor...")
            break
        except Exception as e:
            print(f"[HONEYPOT][{NODE_NAME}] Hata (devam ediliyor): {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
