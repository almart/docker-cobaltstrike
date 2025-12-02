#!/bin/bash
set -e

# Get IP
IPADDRESS="$(ip -4 route get 1 | awk '{print $7; exit}')"

# === DOWNLOAD & CLEAN EXTRACT ===
echo "[+] Downloading Cobalt Strike 4.12..."
token=`curl -s https://download.cobaltstrike.com/download -d "dlkey=${COBALTSTRIKE_KEY}" | grep 'href="/downloads/' | cut -d '/' -f3`
curl -s https://download.cobaltstrike.com/downloads/${token}/latest410/cobaltstrike-dist-linux.tgz -o /tmp/cs.tgz

echo "[+] Extracting cleanly..."
tar zxf /tmp/cs.tgz -C /opt/cobaltstrike --strip-components=1
rm -f /tmp/cs.tgz

# === LICENSE UPDATE ===
echo "[+] Applying license..."
echo "${COBALTSTRIKE_KEY}" | ./update > /dev/null 2>&1

# === START TEAMSERVER ===
echo "[+] Starting teamserver (with --experimental-db)..."
/opt/cobaltstrike/server/teamserver "${IPADDRESS}" "${COBALTSTRIKE_PASS}" \
    "/opt/cobaltstrike/profiles/${COBALTSTRIKE_PROFILE}.profile" \
    ${COBALTSTRIKE_EXP} --experimental-db &

sleep 15

# === START 4.12 REST API  ===
if [ -f "/opt/cobaltstrike/server/rest-server/csrestapi" ]; then
    echo "[+] Starting REST API on 50443"
    /opt/cobaltstrike/server/rest-server/csrestapi \
        --pass "${COBALTSTRIKE_PASS}" \
        --host 0.0.0.0 \
        --port 50443 &
fi

echo ""
echo "Cobalt Strike 4.12 READY"
echo "→ Teamserver: https://${IPADDRESS}:50050"
echo "→ REST API:   https://${IPADDRESS}:50443/v1/"
echo "→ Password:   ${COBALTSTRIKE_PASS}"

tail -f /dev/null
