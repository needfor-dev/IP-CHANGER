#!/bin/bash

HTTP_FILE="Ip-bot-2.0/http.txt"
HTTPS_FILE="Ip-bot-2.0/https.txt"

TEST_URL="https://api.ipify.org"
TIMEOUT=5


check_proxy() {
    local proxy=$1

    curl --silent --fail \
         --proxy "http://$proxy" \
         --connect-timeout "$TIMEOUT" \
         --max-time "$TIMEOUT" \
         "$TEST_URL" >/dev/null 2>&1
}


set_env_proxy() {
    local proxy=$1

    export http_proxy="http://$proxy"
    export https_proxy="http://$proxy"
    export HTTP_PROXY="http://$proxy"
    export HTTPS_PROXY="http://$proxy"
}


set_gnome_proxy() {
    local proxy=$1
    local ip="${proxy%:*}"
    local port="${proxy#*:}"

    gsettings set org.gnome.system.proxy mode 'manual'

    gsettings set org.gnome.system.proxy.http host "$ip"
    gsettings set org.gnome.system.proxy.http port "$port"

    gsettings set org.gnome.system.proxy.https host "$ip"
    gsettings set org.gnome.system.proxy.https port "$port"
}


mapfile -t PROXIES < <(
    cat "$HTTP_FILE" "$HTTPS_FILE" 2>/dev/null |
    grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' |
    sort -u |
    shuf
)

if [ "${#PROXIES[@]}" -eq 0 ]; then
    echo "[-] No proxies found"
    exit 1
fi

echo "[+] Selecting a random proxy..."


for proxy in "${PROXIES[@]}"; do
    echo -n "Testing $proxy ... "

    if check_proxy "$proxy"; then
        echo "WORKING"

        set_env_proxy "$proxy"
        set_gnome_proxy "$proxy"

        echo
        echo "[+] Proxy applied successfully:"
        echo "    IP   : ${proxy%:*}"
        echo "    Port : ${proxy#*:}"
        echo "    GNOME + Terminal updated"

        exit 0
    else
        echo "DEAD"
    fi
done

echo
echo "[-] No working proxy found"
exit 1
