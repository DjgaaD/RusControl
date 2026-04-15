#!/bin/sh
set -eu

BRANCH_MAIN="main"
BRANCH_24="openwrt-24"
BRANCH_25="openwrt-25"
REPO_BASE="https://raw.githubusercontent.com/DjgaaD/RusControl"
TARGET_VERSION="${1:-auto}"

download_file() {
    local src="$1"
    local dst="$2"

    if command -v uclient-fetch >/dev/null 2>&1; then
        uclient-fetch -q -O "$dst" "$src"
        return
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$dst" "$src"
        return
    fi
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$src" -o "$dst"
        return
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

install_profile() {
    local version="$1"
    local branch repo
    branch="$(resolve_branch "$version")"
    repo="${REPO_BASE}/${branch}"

    echo "=== WiFi Manager Installer (${version}) ==="
    echo "Источник: ${repo}"

    mkdir -p /www/cgi-bin
    touch /etc/wifi_whitelist

    for f in lib_ruscontrol.sh block unblock devices schedule schedule_del whitelist wifi_block wifi_unblock wifi_block_all wifi_unblock_all block_all_now unblock_all_now; do
        download_file "${repo}/cgi-bin/${f}" "/www/cgi-bin/${f}"
        chmod +x "/www/cgi-bin/${f}"
    done

    /etc/init.d/cron enable
    /etc/init.d/cron start

    echo ""
    echo "=== Установка завершена! ==="
    echo "Откройте: http://$(uci get network.lan.ipaddr)/cgi-bin/devices"
}

install_profile "$TARGET_VERSION"