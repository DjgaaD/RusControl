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
