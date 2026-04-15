#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/../../.." && pwd)
OUT_DIR="${ROOT_DIR}/dist"
WORK_DIR="${ROOT_DIR}/.build-ipk"

TARGET_VERSION="${1:-24}"
PKG_VERSION="${2:-1.0.0}"
PKG_RELEASE="${3:-1}"

case "$TARGET_VERSION" in
    24) ;;
    *)
        echo "Usage: $0 <24> [version] [release]" >&2
        echo "OpenWrt 25 uses APK packages, not IPK." >&2
        exit 1
        ;;
esac

PKG_NAME="luci-app-ruscontrol-owrt24"
PKG_ARCH="all"
PKG_FILENAME="${PKG_NAME}_${PKG_VERSION}-${PKG_RELEASE}_${PKG_ARCH}.ipk"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/control" "$WORK_DIR/data/www/cgi-bin" \
    "$WORK_DIR/data/usr/share/luci/view/ruscontrol" \
    "$WORK_DIR/data/usr/share/luci/menu.d" \
    "$WORK_DIR/data/usr/share/luci/acl.d" \
    "$OUT_DIR"

for f in lib_ruscontrol.sh block unblock devices schedule schedule_del whitelist wifi_block wifi_unblock wifi_block_all wifi_unblock_all block_all_now unblock_all_now; do
    cp "${ROOT_DIR}/cgi-bin/${f}" "$WORK_DIR/data/www/cgi-bin/${f}"
    chmod 0755 "$WORK_DIR/data/www/cgi-bin/${f}"
done

cp "${ROOT_DIR}/luci/view/ruscontrol/devices.js" "$WORK_DIR/data/usr/share/luci/view/ruscontrol/devices.js"
cp "${ROOT_DIR}/luci/view/ruscontrol/schedule.js" "$WORK_DIR/data/usr/share/luci/view/ruscontrol/schedule.js"
cp "${ROOT_DIR}/luci/view/ruscontrol/whitelist.js" "$WORK_DIR/data/usr/share/luci/view/ruscontrol/whitelist.js"
cp "${ROOT_DIR}/luci/menu.d/luci-app-ruscontrol.json" "$WORK_DIR/data/usr/share/luci/menu.d/luci-app-ruscontrol.json"
cp "${ROOT_DIR}/luci/acl.d/luci-app-ruscontrol.json" "$WORK_DIR/data/usr/share/luci/acl.d/luci-app-ruscontrol.json"

INSTALLED_SIZE=$(du -ks "$WORK_DIR/data" | awk '{print $1}')
cat > "$WORK_DIR/control/control" <<EOF
Package: ${PKG_NAME}
Version: ${PKG_VERSION}-${PKG_RELEASE}
Depends: luci-base, uhttpd, iwinfo, ubus, hostapd-common
Section: luci
Category: LuCI
Title: RusControl WiFi Manager (OpenWrt ${TARGET_VERSION})
Architecture: ${PKG_ARCH}
Installed-Size: ${INSTALLED_SIZE}
Maintainer: RusControl
Description: Web UI for WiFi MAC blocking, whitelist and schedule.
EOF

cat > "$WORK_DIR/control/postinst" <<'EOF'
#!/bin/sh
set -e

touch /etc/wifi_whitelist
chmod 0644 /etc/wifi_whitelist
chmod 0755 /www/cgi-bin/lib_ruscontrol.sh \
    /www/cgi-bin/block /www/cgi-bin/unblock /www/cgi-bin/devices \
    /www/cgi-bin/schedule /www/cgi-bin/schedule_del /www/cgi-bin/whitelist \
    /www/cgi-bin/wifi_block /www/cgi-bin/wifi_unblock \
    /www/cgi-bin/wifi_block_all /www/cgi-bin/wifi_unblock_all \
    /www/cgi-bin/block_all_now /www/cgi-bin/unblock_all_now

/etc/init.d/cron enable >/dev/null 2>&1 || true
/etc/init.d/cron start >/dev/null 2>&1 || true

exit 0
EOF
chmod 0755 "$WORK_DIR/control/postinst"

cat > "$WORK_DIR/control/prerm" <<'EOF'
#!/bin/sh
set -e
# Keep /etc/wifi_whitelist on uninstall to preserve user settings.
exit 0
EOF
chmod 0755 "$WORK_DIR/control/prerm"

echo "2.0" > "$WORK_DIR/debian-binary"

(
    cd "$WORK_DIR/control"
    tar -czf "$WORK_DIR/control.tar.gz" .
)
(
    cd "$WORK_DIR/data"
    tar -czf "$WORK_DIR/data.tar.gz" .
)

ar -r "$OUT_DIR/$PKG_FILENAME" "$WORK_DIR/debian-binary" "$WORK_DIR/control.tar.gz" "$WORK_DIR/data.tar.gz" >/dev/null

echo "Built package: $OUT_DIR/$PKG_FILENAME"
