#!/bin/bash

set -a
ENV_FILE="/opt/syncshield/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    echo "[WATCHER] .env dosyası yüklendi."
else
    echo "[WATCHER] .env bulunamadı: $ENV_FILE"
    echo "[WATCHER] Telegram bildirimleri devre dışı kalacak."
fi
set +a

NODE_NAME="${NODE_NAME:-unknown}"
BANNED_FILE="/var/sync_intel/banned_ips.txt"
PROCESSED_FILE="/tmp/watcher_processed_ips.txt"

touch "$PROCESSED_FILE"

mkdir -p "$(dirname "$BANNED_FILE")"
touch "$BANNED_FILE"

lookup_geoip() {
    local ip="$1"
    local raw

    raw=$(curl -s --max-time 5 "http://ip-api.com/line/${ip}?fields=country,city,isp" 2>/dev/null)

    if [ -n "$raw" ]; then
        GEOIP_COUNTRY=$(echo "$raw" | sed -n '1p')
        GEOIP_CITY=$(echo "$raw" | sed -n '2p')
        GEOIP_ISP=$(echo "$raw" | sed -n '3p')
    else
        GEOIP_COUNTRY="Bilinmiyor"
        GEOIP_CITY="Bilinmiyor"
        GEOIP_ISP="Bilinmiyor"
    fi
}

send_telegram() {
    local ip="$1"
    local country="$2"
    local city="$3"
    local isp="$4"
    local message="[TEHDIT ENGELLENDI] ${ip} (${country} / ${city}) bloklandı. Saglayici: ${isp}"

    if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
        echo "[WATCHER][${NODE_NAME}] Telegram bilgileri eksik, bildirim atlanıyor."
        return
    fi

    local url="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

    curl -s -X POST "$url" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" \
        -d parse_mode="HTML" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "[WATCHER][${NODE_NAME}] Telegram gönderildi: ${ip}"
    else
        echo "[WATCHER][${NODE_NAME}] Telegram gönderilemedi: ${ip}"
    fi
}

block_ip() {
    local ip="$1"

    if [ -z "$ip" ]; then
        return
    fi

    if grep -qF "$ip" "$PROCESSED_FILE" 2>/dev/null; then
        return
    fi

    echo "[WATCHER][${NODE_NAME}] Yeni IP: ${ip}"

    if ipset add syncshield_block "$ip" 2>/dev/null; then
        echo "[WATCHER][${NODE_NAME}] IP engellendi: ${ip}"
    else
        echo "[WATCHER][${NODE_NAME}] Mac ortami - ipset simule edildi: ${ip}"
    fi

    echo "[WATCHER][${NODE_NAME}] GeoIP sorgusu: ${ip}"
    lookup_geoip "$ip"
    echo "[WATCHER][${NODE_NAME}] ${ip} -> ${GEOIP_COUNTRY} / ${GEOIP_CITY} | ISP: ${GEOIP_ISP}"

    send_telegram "$ip" "$GEOIP_COUNTRY" "$GEOIP_CITY" "$GEOIP_ISP"

    echo "$ip" >> "$PROCESSED_FILE"
}

echo "[WATCHER][${NODE_NAME}] Mevcut IP'ler kontrol ediliyor..."
while IFS= read -r line; do
    ip=$(echo "$line" | awk '{print $NF}')
    block_ip "$ip"
done < "$BANNED_FILE"

echo "[WATCHER][${NODE_NAME}] Dinleniyor: ${BANNED_FILE} (close_write)"

inotifywait -m -e close_write "$BANNED_FILE" --format '%e' 2>/dev/null | while read -r event; do
    last_line=$(tail -n 1 "$BANNED_FILE" 2>/dev/null)
    ip=$(echo "$last_line" | awk '{print $NF}')
    block_ip "$ip"
done
