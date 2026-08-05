#!/bin/sh
set -eu

KEEP_WHITELIST=1

usage() {
    echo "Uninstall RusControl (OpenWrt 24/25)"
    echo "Usage:"
    echo "  /tmp/uninstall.sh            # remove RusControl, keep /etc/wifi_whitelist"
    echo "  /tmp/uninstall.sh purge     # remove RusControl and /etc/wifi_whitelist"
}

for arg in "$@"; do
    case "$arg" in
        purge|--purge-whitelist)
            KEEP_WHITELIST=0
            ;;
        keep|--keep-whitelist)
            KEEP_WHITELIST=1
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

rmf() {
    rm -f "$@" 2>/dev/null || true
}

remove_paths() {
    # CGI scripts
    rmf /www/cgi-bin/lib_ruscontrol.sh /www/cgi-bin/block /www/cgi-bin/unblock /www/cgi-bin/devices \
        /www/cgi-bin/schedule /www/cgi-bin/schedule_del /www/cgi-bin/schedule_once_exec \
        /www/cgi-bin/whitelist /www/cgi-bin/wifi_block /www/cgi-bin/wifi_unblock \
        /www/cgi-bin/wifi_block_all /www/cgi-bin/wifi_unblock_all \
        /www/cgi-bin/block_all_now /www/cgi-bin/unblock_all_now

    # LuCI JS
    rmf /www/luci-static/resources/view/ruscontrol/devices.js \
        /www/luci-static/resources/view/ruscontrol/schedule.js \
        /www/luci-static/resources/view/ruscontrol/whitelist.js

    # LuCI menu + RPCD ACL
    rmf /usr/share/luci/menu.d/luci-app-ruscontrol.json
    rmf /usr/share/rpcd/acl.d/luci-app-ruscontrol.json
    rmf /usr/share/luci/acl.d/luci-app-ruscontrol.json
}

remove_cron_rules() {
    # RusControl schedule rules are stored in /etc/crontabs/root and tagged with '#SCHED'
    [ -f /etc/crontabs/root ] || return 0

    # Backup (best effort)
    cp /etc/crontabs/root /etc/crontabs/root.ruscontrol.bak 2>/dev/null || true

    tmp="/tmp/ruscontrol_root_cron_$$"
    grep -v '#SCHED' /etc/crontabs/root > "$tmp" || true
    mv "$tmp" /etc/crontabs/root

    /etc/init.d/cron restart >/dev/null 2>&1 || true
}

try_opkg_remove() {
    command -v opkg >/dev/null 2>&1 || return 0

    # Remove any installed packages containing 'ruscontrol' (best effort).
    pkgs="$(opkg list-installed 2>/dev/null | grep -i 'ruscontrol' | awk '{print $1}' || true)"
    for p in $pkgs; do
        opkg remove "$p" >/dev/null 2>&1 || true
    done
}

cleanup_services() {
    /etc/init.d/rpcd restart >/dev/null 2>&1 || true
    /etc/init.d/uhttpd restart >/dev/null 2>&1 || true
    rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/* 2>/dev/null || true
}

remove_paths
remove_cron_rules
try_opkg_remove

if [ "$KEEP_WHITELIST" -eq 0 ]; then
    rmf /etc/wifi_whitelist
fi

cleanup_services

echo "RusControl removed."
if [ "$KEEP_WHITELIST" -eq 0 ]; then
    echo "Note: /etc/wifi_whitelist was removed too (purge mode)."
else
    echo "Note: /etc/wifi_whitelist was kept."
fi

