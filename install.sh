#!/bin/sh
echo "=== WiFi Manager Installer ==="
mkdir -p /www/cgi-bin
touch /etc/wifi_whitelist

# Скачиваем файлы
REPO="https://raw.githubusercontent.com/DjgaaD/RusControl/main"

for f in block unblock devices schedule schedule_del whitelist wifi_block wifi_unblock wifi_block_all wifi_unblock_all block_all_now unblock_all_now; do
    wget -O "/www/cgi-bin/$f" "${REPO}/cgi-bin/${f}"
    chmod +x "/www/cgi-bin/$f"
done

# Включаем cron
/etc/init.d/cron enable
/etc/init.d/cron start

echo ""
echo "=== Установка завершена! ==="
echo "Откройте: http://$(uci get network.lan.ipaddr)/cgi-bin/devices"