#!/bin/bash

NODE_NAME="${NODE_NAME:-unknown}"
WATCH_DIR="/var/sync_intel"
LOG_FILE="${WATCH_DIR}/monitor_${NODE_NAME}.log"

echo "[MONITOR][${NODE_NAME}] Dizin izleme başlatıldı: ${WATCH_DIR}"

mkdir -p "${WATCH_DIR}"

inotifywait -m -r -e create,modify,delete,moved_to "${WATCH_DIR}" --format '%T %w%f %e' --timefmt '%Y-%m-%dT%H:%M:%S' 2>/dev/null | while read -r TIMESTAMP FILEPATH EVENT; do
    if [[ "${FILEPATH}" == *"monitor_${NODE_NAME}.log"* ]]; then
        continue
    fi

    LOG_ENTRY="[${TIMESTAMP}][${NODE_NAME}] Olay: ${EVENT} | Dosya: ${FILEPATH}"
    echo "${LOG_ENTRY}"
    echo "${LOG_ENTRY}" >> "${LOG_FILE}"

    if [[ "${EVENT}" == *"CREATE"* ]] || [[ "${EVENT}" == *"MOVED_TO"* ]]; then
        echo "[MONITOR][${NODE_NAME}] Yeni dosya: ${FILEPATH}"
    fi

    if [[ "${EVENT}" == *"MODIFY"* ]]; then
        echo "[MONITOR][${NODE_NAME}] Guncellendi: ${FILEPATH}"
    fi

    if [[ "${EVENT}" == *"DELETE"* ]]; then
        echo "[MONITOR][${NODE_NAME}] Silindi: ${FILEPATH}"
    fi
done
# agdaki degisiklikleri ve ip'leri takip eden script git add scripts/monitor.shgit commit -m IP takip ve ağ izleme mekanizması eklendi
# agdaki degisiklikleri ve ip'leri takip eden script
