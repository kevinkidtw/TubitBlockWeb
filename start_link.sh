#!/bin/bash
# =====================================================================
# TubitBlockWeb 一鍵啟動環境 (Mac/Linux)
# 功能：自動安裝 Node.js、偵測 CPU 架構、下載對應的 ESP32 編譯器、
#       啟動 HTTP 靜態伺服器與 tubitblock-link 連線服務。
# =====================================================================

set -e

echo "======================================================="
echo "TubitBlockWeb 一鍵啟動環境 (Mac/Linux)"
echo "======================================================="
echo "正在檢查系統環境..."

# ---- 第一步：檢查 Node.js ----
if ! command -v npm &> /dev/null; then
    echo ""
    echo "找不到 Node.js (npm)，準備進行自動安裝..."
    if [ "$(uname)" == "Darwin" ]; then
        if command -v brew &> /dev/null; then
            echo "偵測到 Homebrew，正在安裝 Node.js..."
            brew install node
        else
            echo "正在下載 Node.js Mac 版安裝檔 (LTS)..."
            curl -o /tmp/nodejs.pkg "https://nodejs.org/dist/v20.11.1/node-v20.11.1.pkg"
            echo "即將安裝 Node.js，請輸入您的 Mac 電腦密碼以授權："
            sudo installer -pkg /tmp/nodejs.pkg -target /
            rm -f /tmp/nodejs.pkg
        fi
    elif [ "$(uname -s | cut -c1-5)" == "Linux" ]; then
        echo "正在為 Linux 系統安裝 Node.js..."
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        else
            echo "[錯誤] 目前僅支援使用 apt 的 Linux 系統自動安裝。"
            echo "請手動前往 https://nodejs.org/ 下載。安裝後重新執行此腳本。"
            exit 1
        fi
    else
        echo "[錯誤] 未知的作業系統，無法自動安裝 Node.js！"
        exit 1
    fi

    if ! command -v npm &> /dev/null; then
        echo ""
        echo "======================================================="
        echo "自動安裝似乎未成功，請嘗試手動前往 https://nodejs.org/ 安裝，"
        echo "安裝完畢後，請重新開啟這個終端機視窗並重試。"
        echo "======================================================="
        exit 1
    fi
    echo ""
    echo "======================================================="
    echo "Node.js (npm) 安裝成功！"
    echo "由於環境變數更新，請先關閉這個終端機視窗，然後重新執行腳本一次！"
    echo "======================================================="
    exit 0
fi

# ---- 第二步：定位專案目錄 ----
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$SCRIPT_DIR/tubitblock-link" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/TubitBlockWeb/tubitblock-link" ]; then
    PROJECT_ROOT="$SCRIPT_DIR/TubitBlockWeb"
else
    echo ""
    echo "找不到 tubitblock-link 目錄，準備自動下載專案..."
    if command -v git &> /dev/null; then
        echo "系統具備 Git，開始從 GitHub 複製專案..."
        cd "$SCRIPT_DIR"
        git clone --depth 1 https://github.com/kevinkidtw/TubitBlockWeb.git
    else
        echo "系統找不到 Git，改用 curl 下載壓縮包..."
        cd "$SCRIPT_DIR"
        curl -L -o TubitBlockWeb.zip https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip
        unzip -q TubitBlockWeb.zip
        rm TubitBlockWeb.zip
        mv TubitBlockWeb-main TubitBlockWeb
    fi
    PROJECT_ROOT="$SCRIPT_DIR/TubitBlockWeb"
fi

LINK_DIR="$PROJECT_ROOT/tubitblock-link"
TOOLS_DIR="$LINK_DIR/tools/Arduino/packages/esp32/tools"

# ---- 第三步：偵測 CPU 架構並下載對應的 ESP32 編譯器 ----
echo ""
echo "======================================================="
echo "正在檢查 ESP32 編譯器工具鏈..."
echo "======================================================="

OS_NAME="$(uname -s)"
ARCH="$(uname -m)"

echo "  作業系統: $OS_NAME"
echo "  CPU 架構: $ARCH"

# 判斷需要下載的平台標籤
if [ "$OS_NAME" == "Darwin" ]; then
    if [ "$ARCH" == "arm64" ]; then
        PLATFORM_LABEL="macOS ARM64 (Apple Silicon)"
        ESP_X32_URL="https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/xtensa-esp-elf-13.2.0_20240530-aarch64-apple-darwin.tar.gz"
        ESP_RV32_URL="https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/riscv32-esp-elf-13.2.0_20240530-aarch64-apple-darwin.tar.gz"
        ESPTOOL_URL="https://github.com/espressif/arduino-esp32/releases/download/3.1.0-RC3/esptool-v4.9.dev3-macos-arm64.tar.gz"
        OPENOCD_URL="https://github.com/espressif/openocd-esp32/releases/download/v0.12.0-esp32-20241016/openocd-esp32-macos-arm64-0.12.0-esp32-20241016.tar.gz"
        GDB_XTENSA_URL="https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v14.2_20240403/xtensa-esp-elf-gdb-14.2_20240403-aarch64-apple-darwin21.1.tar.gz"
        GDB_RV32_URL="https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v14.2_20240403/riscv32-esp-elf-gdb-14.2_20240403-aarch64-apple-darwin21.1.tar.gz"
    else
        PLATFORM_LABEL="macOS Intel (x86_64)"
        ESP_X32_URL="https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/xtensa-esp-elf-13.2.0_20240530-x86_64-apple-darwin.tar.gz"
        ESP_RV32_URL="https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/riscv32-esp-elf-13.2.0_20240530-x86_64-apple-darwin.tar.gz"
        ESPTOOL_URL="https://github.com/espressif/arduino-esp32/releases/download/3.1.0-RC3/esptool-v4.9.dev3-macos-amd64.tar.gz"
        OPENOCD_URL="https://github.com/espressif/openocd-esp32/releases/download/v0.12.0-esp32-20241016/openocd-esp32-macos-amd64-0.12.0-esp32-20241016.tar.gz"
        GDB_XTENSA_URL="https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v14.2_20240403/xtensa-esp-elf-gdb-14.2_20240403-x86_64-apple-darwin14.tar.gz"
        GDB_RV32_URL="https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v14.2_20240403/riscv32-esp-elf-gdb-14.2_20240403-x86_64-apple-darwin14.tar.gz"
    fi
elif [ "$OS_NAME" == "Linux" ]; then
    PLATFORM_LABEL="Linux x86_64"
    ESP_X32_URL="https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/xtensa-esp-elf-13.2.0_20240530-x86_64-linux-gnu.tar.gz"
    ESP_RV32_URL="https://github.com/espressif/crosstool-NG/releases/download/esp-13.2.0_20240530/riscv32-esp-elf-13.2.0_20240530-x86_64-linux-gnu.tar.gz"
    ESPTOOL_URL="https://github.com/espressif/arduino-esp32/releases/download/3.1.0-RC3/esptool-v4.9.dev3-linux-amd64.tar.gz"
    OPENOCD_URL="https://github.com/espressif/openocd-esp32/releases/download/v0.12.0-esp32-20241016/openocd-esp32-linux-amd64-0.12.0-esp32-20241016.tar.gz"
    GDB_XTENSA_URL="https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v14.2_20240403/xtensa-esp-elf-gdb-14.2_20240403-x86_64-linux-gnu.tar.gz"
    GDB_RV32_URL="https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v14.2_20240403/riscv32-esp-elf-gdb-14.2_20240403-x86_64-linux-gnu.tar.gz"
else
    echo "[錯誤] 不支援的作業系統: $OS_NAME"
    exit 1
fi

echo "  對應平台: $PLATFORM_LABEL"

# ---- 下載函數 ----
# 用法: download_tool "工具名稱" "下載URL" "目標目錄" "解壓後的頂層資料夾名"
download_tool() {
    local TOOL_NAME="$1"
    local URL="$2"
    local DEST_DIR="$3"
    local STRIP_PREFIX="$4"  # tar 解壓時要去掉的頂層目錄名

    if [ -d "$DEST_DIR" ] && [ "$(ls -A "$DEST_DIR" 2>/dev/null)" ]; then
        echo "  [✓] $TOOL_NAME 已存在，跳過下載"
        return 0
    fi

    echo "  [↓] 正在下載 $TOOL_NAME ..."
    local TMP_FILE="/tmp/esp32_tool_$$_$(basename "$URL")"
    curl -L --progress-bar -o "$TMP_FILE" "$URL"

    echo "  [⚙] 正在解壓 $TOOL_NAME ..."
    mkdir -p "$DEST_DIR"

    if [ -n "$STRIP_PREFIX" ]; then
        # 解壓並去掉頂層目錄，直接放到 DEST_DIR
        tar xzf "$TMP_FILE" -C "$DEST_DIR" --strip-components=1
    else
        tar xzf "$TMP_FILE" -C "$DEST_DIR"
    fi

    rm -f "$TMP_FILE"
    echo "  [✓] $TOOL_NAME 下載完成"
}

echo ""

# 下載 6 個 OS-specific 工具
download_tool "esp-x32 (Xtensa 編譯器)" \
    "$ESP_X32_URL" \
    "$TOOLS_DIR/esp-x32/2405" \
    "xtensa-esp-elf"

download_tool "esp-rv32 (RISC-V 編譯器)" \
    "$ESP_RV32_URL" \
    "$TOOLS_DIR/esp-rv32/2405" \
    "riscv32-esp-elf"

download_tool "esptool_py (燒錄工具)" \
    "$ESPTOOL_URL" \
    "$TOOLS_DIR/esptool_py/4.9.dev3" \
    "esptool"

download_tool "openocd-esp32 (除錯工具)" \
    "$OPENOCD_URL" \
    "$TOOLS_DIR/openocd-esp32/v0.12.0-esp32-20241016" \
    "openocd-esp32"

download_tool "xtensa-esp-elf-gdb (Xtensa GDB)" \
    "$GDB_XTENSA_URL" \
    "$TOOLS_DIR/xtensa-esp-elf-gdb/14.2_20240403" \
    "xtensa-esp-elf-gdb"

download_tool "riscv32-esp-elf-gdb (RISC-V GDB)" \
    "$GDB_RV32_URL" \
    "$TOOLS_DIR/riscv32-esp-elf-gdb/14.2_20240403" \
    "riscv32-esp-elf-gdb"

echo ""
echo "  ESP32 編譯器工具鏈就緒 ✓"

# ---- 第四步：安裝 npm 依賴 ----
echo ""
echo "正在檢查並安裝專案依賴套件 (npm install)..."
cd "$LINK_DIR"
npm install

# ---- 第五步：啟動服務 ----
echo ""
echo "======================================================="
echo "TubitBlockWeb - 服務啟動中..."
echo "請勿關閉此終端機視窗，把它最小化即可！"
echo "======================================================="
echo ""

# 先關閉之前可能殘留的 HTTP 伺服器
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

# 啟動 HTTP 靜態檔案伺服器 (port 8080)
echo "正在啟動 HTTP 靜態伺服器 (port 8080)..."
cd "$PROJECT_ROOT"
nohup python3 -m http.server 8080 -d "$PROJECT_ROOT" > "$PROJECT_ROOT/http_server.log" 2>&1 &
HTTP_PID=$!
echo "HTTP 伺服器已啟動 (PID: $HTTP_PID)"
echo ""
echo "======================================================="
echo "請用瀏覽器開啟: http://localhost:8080/www/index.html"
echo "======================================================="
echo ""

# 開始執行背景連線服務 (tubitblock-link, port 20111)
cd "$LINK_DIR"
npm start

# 當 npm start 結束時，也關閉 HTTP 伺服器
kill $HTTP_PID 2>/dev/null
