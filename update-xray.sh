
#!/usr/bin/env bash

set -Eeuo pipefail

# --------------------------------------------------
# Configuration
# --------------------------------------------------

XRAY_VERSION="${1:-}"

XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip"

BIN_DIR="/usr/local/bin"
DATA_DIR="/usr/local/share/xray"

TMP_DIR="$(mktemp -d)"
ARCHIVE="${TMP_DIR}/Xray-linux-64.zip"
EXTRACT_DIR="${TMP_DIR}/extract"

# --------------------------------------------------
# Cleanup
# --------------------------------------------------

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

# --------------------------------------------------
# Error handler
# --------------------------------------------------

error_handler() {
    local exit_code=$?

    echo
    echo "[ERROR] Update failed (exit code: ${exit_code})"

    if systemctl is-active --quiet xray; then
        echo "[INFO] Xray service is running."
    else
        echo "[WARNING] Xray service is not running!"
    fi

    exit "$exit_code"
}

trap error_handler ERR

# --------------------------------------------------
# Validation
# --------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Run this script as root (sudo)."
    exit 1
fi

if [[ -z "$XRAY_VERSION" ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v26.10.29"
    exit 1
fi

if [[ ! "$XRAY_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[ERROR] Invalid version: $XRAY_VERSION"
    exit 1
fi

for cmd in curl unzip systemctl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] Required command not found: $cmd"
        exit 1
    fi
done

if ! systemctl cat xray >/dev/null 2>&1; then
    echo "[ERROR] Systemd service xray not found."
    exit 1
fi

mkdir -p "$BIN_DIR" "$DATA_DIR" "$EXTRACT_DIR"

# --------------------------------------------------
# Download
# --------------------------------------------------

echo "[INFO] Downloading Xray ${XRAY_VERSION}..."

curl -fL --retry 3 \
    "$XRAY_URL" \
    -o "$ARCHIVE"

# --------------------------------------------------
# Extract
# --------------------------------------------------

echo "[INFO] Extracting archive..."

unzip -q "$ARCHIVE" -d "$EXTRACT_DIR"

XRAY_BINARY="${EXTRACT_DIR}/xray"

if [[ ! -f "$XRAY_BINARY" ]]; then
    echo "[ERROR] Xray binary not found in archive."
    exit 1
fi

if [[ ! -x "$XRAY_BINARY" ]]; then
    chmod +x "$XRAY_BINARY"
fi

shopt -s nullglob
DAT_FILES=("$EXTRACT_DIR"/*.dat)

if (( ${#DAT_FILES[@]} == 0 )); then
    echo "[ERROR] No .dat files found in archive."
    exit 1
fi

# --------------------------------------------------
# Stop service
# --------------------------------------------------

echo "[INFO] Stopping Xray service..."

systemctl stop xray

# --------------------------------------------------
# Install binary
# --------------------------------------------------

echo "[INFO] Installing Xray binary..."

install -m 0755 "$XRAY_BINARY" "${BIN_DIR}/xray"

# --------------------------------------------------
# Install data files
# --------------------------------------------------

echo "[INFO] Installing .dat files..."

install -m 0644 "${DAT_FILES[@]}" "$DATA_DIR/"

# --------------------------------------------------
# Start service
# --------------------------------------------------

echo "[INFO] Starting Xray service..."

systemctl start xray

# --------------------------------------------------
# Status
# --------------------------------------------------

echo
echo "========================================"
echo " Xray ${XRAY_VERSION} update completed"
echo "========================================"
echo

echo "[INFO] Installed version:"
"${BIN_DIR}/xray" version

echo
echo "[INFO] Service status:"

systemctl status xray --no-pager -l
