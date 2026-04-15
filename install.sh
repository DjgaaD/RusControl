#!/bin/sh
set -eu

BRANCH_MAIN="main"
BRANCH_24="openwrt-24"
BRANCH_25="openwrt-25"
REPO_BASE="https://raw.githubusercontent.com/DjgaaD/RusControl"
TARGET_VERSION="${1:-auto}"

download_file_try() {
    local src="$1"
    local dst="$2"

    if command -v uclient-fetch >/dev/null 2>&1; then
        uclient-fetch -q -O "$dst" "$src" >/dev/null 2>&1 && return 0
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$dst" "$src" >/dev/null 2>&1 && return 0
    fi
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$src" -o "$dst" >/dev/null 2>&1 && return 0
    fi
    return 1
}

ensure_downloader() {
    if command -v uclient-fetch >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1; then
        return 0
    fi
    echo "❌ Не найден загрузчик (uclient-fetch/wget/curl)." >&2
    exit 1
}

detect_openwrt_major() {
    local rel major
    if [ -r /etc/openwrt_release ]; then
        rel=$(sed -n "s/^DISTRIB_RELEASE=['\"]\\([0-9][0-9]*\\).*/\\1/p" /etc/openwrt_release | head -n1)
        [ -n "$rel" ] && echo "$rel" && return
    fi
    if [ -r /etc/os-release ]; then
        rel=$(sed -n "s/^VERSION_ID=['\"]\\([0-9][0-9]*\\).*/\\1/p" /etc/os-release | head -n1)
        [ -n "$rel" ] && echo "$rel" && return
    fi
    major=$(ubus call system board 2>/dev/null | sed -n 's/.*"release":"\([0-9][0-9]*\)\..*/\1/p' | head -n1)
    [ -n "$major" ] && echo "$major" && return
    echo ""
}

resolve_branch() {
    local version="$1"
    case "$version" in
        24|openwrt24|owrt24) echo "$BRANCH_24" ;;
        25|openwrt25|owrt25) echo "$BRANCH_25" ;;
        auto)
            local major
            major="$(detect_openwrt_major)"
            case "$major" in
                24) echo "$BRANCH_24" ;;
                25) echo "$BRANCH_25" ;;
                *)
                    echo "$BRANCH_MAIN"
                    echo "⚠️  Не удалось точно определить OpenWrt (найдено: '${major:-unknown}'). Использую ветку '${BRANCH_MAIN}'." >&2
                    ;;
            esac
            ;;
        *)
            echo "$BRANCH_MAIN"
            echo "⚠️  Неизвестный профиль '${version}'. Использую ветку '${BRANCH_MAIN}'." >&2
            ;;
    esac
}

download_project_file() {
    local relpath="$1"
    local dst="$2"
    local version="$3"
    local branch candidate found=0

    branch="$(resolve_branch "$version")"

    # Try version branch first, then fallback to main.
    for candidate in "$branch" "$BRANCH_MAIN"; do
        if download_file_try "${REPO_BASE}/${candidate}/${relpath}" "$dst"; then
            found=1
            break
        fi
    done

    if [ "$found" -ne 1 ]; then
        echo "❌ Не удалось скачать ${relpath} (проверены ветки: ${branch}, ${BRANCH_MAIN})" >&2
        exit 1
    fi
}

install_profile() {
    local version="$1"
    local branch
    branch="$(resolve_branch "$version")"

    ensure_downloader

    echo "=== WiFi Manager Installer (${version}) ==="
    echo "Источник: ${REPO_BASE}/${branch} (fallback: ${REPO_BASE}/${BRANCH_MAIN})"

    mkdir -p /www/cgi-bin
    mkdir -p /www/luci-static/resources/view/ruscontrol
    mkdir -p /usr/share/luci/menu.d
    mkdir -p /usr/share/rpcd/acl.d

    touch /etc/wifi_whitelist

    for f in lib_ruscontrol.sh block unblock devices schedule schedule_del whitelist wifi_block wifi_unblock wifi_block_all wifi_unblock_all block_all_now unblock_all_now; do
        download_project_file "cgi-bin/${f}" "/www/cgi-bin/${f}" "$version"
        chmod +x "/www/cgi-bin/${f}"
    done

    for f in devices.js schedule.js whitelist.js; do
        download_project_file "luci/view/ruscontrol/${f}" "/www/luci-static/resources/view/ruscontrol/${f}" "$version"
    done

    download_project_file "luci/menu.d/luci-app-ruscontrol.json" "/usr/share/luci/menu.d/luci-app-ruscontrol.json" "$version"
    download_project_file "luci/acl.d/luci-app-ruscontrol.json" "/usr/share/rpcd/acl.d/luci-app-ruscontrol.json" "$version"

    # Remove old wrong ACL location if it exists from previous installs.
    rm -f /usr/share/luci/acl.d/luci-app-ruscontrol.json 2>/dev/null || true

    /etc/init.d/cron enable >/dev/null 2>&1 || true
    /etc/init.d/cron start >/dev/null 2>&1 || true
    rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/* 2>/dev/null || true
    /etc/init.d/rpcd restart >/dev/null 2>&1 || true
    /etc/init.d/uhttpd restart >/dev/null 2>&1 || true

    echo ""
    echo "=== Установка завершена! ==="
    echo "Откройте: http://$(uci get network.lan.ipaddr)/cgi-bin/devices"
}

install_profile "$TARGET_VERSION"