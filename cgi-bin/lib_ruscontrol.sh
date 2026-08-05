#!/bin/sh

urldecode() {
    local data
    data=$(printf '%s' "$1" | tr '+' ' ')
    printf '%b' "$(printf '%s' "$data" | sed 's/%/\\x/g')"
}

get_query_param() {
    local key="$1"
    local value
    value=$(printf '%s' "$QUERY_STRING" | sed -n "s/.*[&]${key}=\([^&]*\).*/\1/p")
    [ -z "$value" ] && value=$(printf '%s' "$QUERY_STRING" | sed -n "s/^${key}=\([^&]*\).*/\1/p")
    urldecode "$value"
}

post_param() {
    local data="$1"
    local key="$2"
    local value
    value=$(printf '%s' "$data" | sed -n "s/.*[&]${key}=\([^&]*\).*/\1/p")
    [ -z "$value" ] && value=$(printf '%s' "$data" | sed -n "s/^${key}=\([^&]*\).*/\1/p")
    urldecode "$value"
}

normalize_mac() {
    printf '%s' "$1" | tr 'A-F' 'a-f'
}

parse_mac_input() {
    local raw part1 part2 part3 part4 part5 part6
    raw=$(printf '%s' "$1" | tr 'A-F' 'a-f' | tr -d ' \t\r\n')
    case "$raw" in
        *:*|*-*)
            printf '%s' "$raw" | tr '-' ':'
            ;;
        *)
            raw=$(printf '%s' "$raw" | tr -d '-:')
            if [ "${#raw}" -eq 12 ]; then
                part1=$(printf '%s' "$raw" | cut -c1-2)
                part2=$(printf '%s' "$raw" | cut -c3-4)
                part3=$(printf '%s' "$raw" | cut -c5-6)
                part4=$(printf '%s' "$raw" | cut -c7-8)
                part5=$(printf '%s' "$raw" | cut -c9-10)
                part6=$(printf '%s' "$raw" | cut -c11-12)
                printf '%s:%s:%s:%s:%s:%s' "$part1" "$part2" "$part3" "$part4" "$part5" "$part6"
            else
                printf '%s' "$raw"
            fi
            ;;
    esac
}

is_valid_mac() {
    printf '%s' "$1" | grep -Eq '^([0-9a-f]{2}:){5}[0-9a-f]{2}$'
}

is_valid_mac_or_all() {
    [ "$1" = "ALL" ] && return 0
    is_valid_mac "$1"
}

is_valid_hour() {
    [ "$1" -ge 0 ] 2>/dev/null && [ "$1" -le 23 ] 2>/dev/null
}

is_valid_minute() {
    [ "$1" -ge 0 ] 2>/dev/null && [ "$1" -le 59 ] 2>/dev/null
}

is_valid_days() {
    printf '%s' "$1" | grep -Eq '^[0-6](,[0-6])*$'
}

safe_remove_sched() {
    local tag="$1"
    local file="/etc/crontabs/root"
    local tmp

    [ -f "$file" ] || return 0
    tmp=$(mktemp) || return 1
    grep -Fv "#SCHED_${tag}" "$file" > "$tmp" || true
    mv "$tmp" "$file"
}

safe_remove_sched_rule_id() {
    local rule_id="$1"
    local file="/etc/crontabs/root"
    local tmp

    [ -f "$file" ] || return 0
    tmp=$(mktemp) || return 1
    grep -Fv "#SCHED|${rule_id}|" "$file" > "$tmp" || true
    mv "$tmp" "$file"
}

safe_remove_whitelist_mac() {
    local mac="$1"
    local file="/etc/wifi_whitelist"
    local tmp

    [ -f "$file" ] || return 0
    tmp=$(mktemp) || return 1
    grep -Fivx "$mac" "$file" > "$tmp" || true
    mv "$tmp" "$file"
}

device_alias_file() {
    echo "/etc/wifi_device_names"
}

get_device_alias() {
    local mac="$1"
    local file alias
    file=$(device_alias_file)
    [ -f "$file" ] || { echo ""; return 0; }
    alias=$(awk -F '\t' -v m="$mac" 'tolower($1)==tolower(m){print $2; exit}' "$file")
    printf '%s' "$alias"
}

set_device_alias() {
    local mac="$1"
    local alias="$2"
    local file tmp
    file=$(device_alias_file)
    touch "$file"
    tmp=$(mktemp) || return 1
    awk -F '\t' -v m="$mac" 'tolower($1)!=tolower(m){print}' "$file" > "$tmp" || true
    if [ -n "$alias" ]; then
        printf '%s\t%s\n' "$mac" "$alias" >> "$tmp"
    fi
    mv "$tmp" "$file"
}

display_device_name() {
    local mac="$1"
    local fallback="$2"
    local alias
    alias=$(get_device_alias "$mac")
    if [ -n "$alias" ]; then
        printf '%s' "$alias"
        return
    fi
    printf '%s' "$fallback"
}

html_escape() {
    printf '%s' "$1" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&#39;/g"
}

hostapd_ifaces() {
    ubus list | sed -n 's/^hostapd\.\(.*\)$/\1/p'
}

csrf_token_file() {
    echo "/tmp/ruscontrol_csrf_token"
}

ensure_csrf_token() {
    local file token
    file=$(csrf_token_file)
    if [ ! -s "$file" ]; then
        token=$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')
        [ -n "$token" ] || token="$(date +%s)-$$"
        printf '%s\n' "$token" > "$file"
    fi
    cat "$file" 2>/dev/null
}

csrf_hidden_input() {
    local token
    token=$(ensure_csrf_token)
    printf "<input type='hidden' name='csrf_token' value='%s'>" "$(html_escape "$token")"
}

verify_csrf_token() {
    local provided="$1"
    local expected
    expected=$(ensure_csrf_token)
    [ -n "$provided" ] && [ "$provided" = "$expected" ]
}

donate_banner_css() {
    echo ".donate-banner{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;padding:12px 16px;margin:0 0 12px;border-radius:10px;font-size:1em;box-shadow:0 2px 10px rgba(0,0,0,0.15)}"
    echo ".light .donate-banner{background:linear-gradient(135deg,#ff9800,#ffc107);color:#3b2200;border:2px solid #e65100}"
    echo ".dark .donate-banner{background:linear-gradient(135deg,#e65100,#ff9800);color:#fff8e1;border:2px solid #ffb300;box-shadow:0 2px 14px rgba(0,0,0,0.35)}"
    echo ".donate-banner-text{display:flex;align-items:center;gap:8px;font-weight:bold;font-size:1.05em}"
    echo ".donate-banner-note{font-size:0.85em;opacity:0.95}"
    echo ".donate-banner-actions{display:flex;align-items:center;gap:8px;flex-wrap:wrap}"
    echo ".donate-banner-btn{display:inline-block;padding:8px 16px;border-radius:8px;font-weight:bold;text-decoration:none;white-space:nowrap;box-shadow:0 2px 6px rgba(0,0,0,0.2)}"
    echo ".light .donate-banner-btn{background:#fff;color:#c62800;border:2px solid #fff}"
    echo ".dark .donate-banner-btn{background:#1e1e2e;color:#ffcc80;border:2px solid #ffcc80}"
    echo ".donate-banner-btn:hover{transform:scale(1.03);opacity:0.95}"
}

echo_donate_banner() {
    echo "<div class='donate-banner'>"
    echo "<div class='donate-banner-text'>☕ <span>Понравился RusControl?</span></div>"
    echo "<span class='donate-banner-note'>Проект бесплатный — поддержите разработку</span>"
    echo "<div class='donate-banner-actions'>"
    echo "<a class='donate-banner-btn' href='https://www.donationalerts.com/r/sektantanatoliy' target='_blank' rel='noopener noreferrer'>💛 DonationAlerts</a>"
    echo "<a class='donate-banner-btn' href='https://boosty.to/sektantanatoliy/donate' target='_blank' rel='noopener noreferrer'>🚀 Boosty</a>"
    echo "</div>"
    echo "</div>"
}
