#!/bin/bash
set -e

# Get IP
IPADDRESS="$(ip -4 route get 1 | awk '{print $7; exit}')"

cleanup() {
    echo "Container stopping, shutting down processes..."
    if [ -n "$REST_PID" ]; then kill -SIGTERM "$REST_PID" 2>/dev/null; fi
    if [ -n "$TS_PID" ]; then kill -SIGTERM "$TS_PID" 2>/dev/null; fi
    wait
}
trap 'cleanup' SIGTERM SIGINT

# === DOWNLOAD & CLEAN EXTRACT ===
echo "[+] Downloading Cobalt Strike 4.12..."
token=`curl -s https://download.cobaltstrike.com/download -d "dlkey=${COBALTSTRIKE_KEY}" | grep 'href="/downloads/' | cut -d '/' -f3`

if [[ -z "$token" ]]; then
    echo "Error: Failed to retrieve download token. Check your license key."
    exit 1
fi

curl -s https://download.cobaltstrike.com/downloads/${token}/latest410/cobaltstrike-dist-linux.tgz -o /tmp/cs.tgz

echo "[+] Extracting cleanly..."
tar zxf /tmp/cs.tgz -C /opt/cobaltstrike --strip-components=1
rm -f /tmp/cs.tgz

# === LICENSE UPDATE ===
echo "[+] Applying license..."
echo "${COBALTSTRIKE_KEY}" | ./update 

# === START TEAMSERVER ===
cd /opt/cobaltstrike/server/
echo "[+] Starting teamserver (with --experimental-db)..."
./teamserver "${IPADDRESS}" "${COBALTSTRIKE_PASS}" \
    "/opt/cobaltstrike/profiles/${COBALTSTRIKE_PROFILE}.profile" \
    ${COBALTSTRIKE_EXP} --experimental-db &
TS_PID=$!


echo "[+] Waiting for Teamserver to listen on 50050..."
MAX_RETRIES=60
count=0
while ! (echo > /dev/tcp/127.0.0.1/50050) >/dev/null 2>&1; do
    if ! kill -0 "$TS_PID" 2>/dev/null; then
        echo "Error: Teamserver process died unexpectedly."
        exit 1
    fi
    
    if [ $count -ge $MAX_RETRIES ]; then
        echo "Error: Timed out waiting for Teamserver to start."
        exit 1
    fi
    
    sleep 1
    count=$((count+1))
done

echo "[+] Teamserver port is active. Waiting 15s for full initialization..."
sleep 15

# === START 4.12 REST API  ===
cd /opt/cobaltstrike/server/rest-server/
if [ -f "/opt/cobaltstrike/server/rest-server/csrestapi" ]; then
    echo "[+] Starting REST API..."
    
    # Start in background, but monitor it
    ./csrestapi --host 0.0.0.0 --port 50443 --pass "${COBALTSTRIKE_PASS}" &
    REST_PID=$!
    
    # Quick check to see if it died immediately (e.g. Connection Refused)
    sleep 5
    if ! kill -0 "$REST_PID" 2>/dev/null; then
        echo "[!] REST API failed to start (process died). Attempting one retry..."
        sleep 5
        ./csrestapi --pass "${COBALTSTRIKE_PASS}" &
        REST_PID=$!
    fi
fi

echo ""
echo "Cobalt Strike 4.12 READY"
echo "→ Teamserver: https://${IPADDRESS}:50050"
echo "→ REST API:   Check logs for port (usually 50443)"
echo "→ Password:   ${COBALTSTRIKE_PASS}"

# 4. Process Management
wait -n
exit $?
