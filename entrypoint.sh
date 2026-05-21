#!/bin/bash

echo "============================================"
echo "  SyncShield Node: ${NODE_NAME:-unknown}"
echo "  P2P Threat Intelligence Platform"
echo "============================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Node başlatılıyor..."

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dizin ve dosyalar hazırlanıyor..."
mkdir -p /var/sync_intel
touch /var/sync_intel/banned_ips.txt
echo "[$(date '+%Y-%m-%d %H:%M:%S')] /var/sync_intel/banned_ips.txt hazır."

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ipset küme oluşturuluyor..."
ipset create syncshield_block hash:net || true

echo "[$(date '+%Y-%m-%d %H:%M:%S')] iptables ana engelleme kuralı ekleniyor..."
iptables -I INPUT -m set --match-set syncshield_block src -j DROP || true

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watcher servisi başlatılıyor (arka plan)..."
/opt/syncshield/watcher.sh &
WATCHER_PID=$!
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watcher PID: $WATCHER_PID"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tüm servisler aktif."
echo "============================================"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Honeypot servisi başlatılıyor (ön plan)..."
exec python3 /opt/syncshield/honeypot.py
