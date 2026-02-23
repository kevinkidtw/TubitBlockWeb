#!/bin/bash

echo "======================================================="
echo "TubitBlockWeb 一鍵啟動環境 (Mac/Linux)"
echo "======================================================="
echo "正在檢查系統環境..."

# 檢查 npm 是否安裝
if ! command -v npm &> /dev/null
then
    echo ""
    echo "找不到 Node.js (npm)，準備進行自動安裝..."
    if [ "$(uname)" == "Darwin" ]; then
        if command -v brew &> /dev/null; then
            echo "偵測到 Homebrew，正在安裝 Node.js..."
            brew install node
        else
            echo "正在下載 Node.js Mac 版安裝檔 (LTS)..."
            curl -o nodejs.pkg "https://nodejs.org/dist/v20.11.1/node-v20.11.1.pkg"
            echo "即將安裝 Node.js，請輸入您的 Mac 電腦密碼以授權："
            sudo installer -pkg nodejs.pkg -target /
            rm nodejs.pkg
        fi
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
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
        echo "請手動前往 https://nodejs.org/ 下載。安裝後重新執行此腳本。"
        exit 1
    fi

    # 再次檢查
    if ! command -v npm &> /dev/null
    then
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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$SCRIPT_DIR/openblock-link" ]; then
    cd "$SCRIPT_DIR/openblock-link"
elif [ -d "$SCRIPT_DIR/TubitBlockWeb/openblock-link" ]; then
    cd "$SCRIPT_DIR/TubitBlockWeb/openblock-link"
else
    echo ""
    echo "找不到 openblock-link 目錄，準備自動下載專案..."
    if ! command -v git &> /dev/null
    then
        echo "系統找不到 Git，改用 curl 下載壓縮包..."
        cd "$SCRIPT_DIR"
        curl -L -o TubitBlockWeb.zip https://github.com/kevinkidtw/TubitBlockWeb/archive/refs/heads/main.zip
        unzip -q TubitBlockWeb.zip
        rm TubitBlockWeb.zip
        mv TubitBlockWeb-main TubitBlockWeb
        cd "TubitBlockWeb/openblock-link"
    else
        echo "系統具備 Git，開始從 GitHub 複製專案..."
        cd "$SCRIPT_DIR"
        git clone https://github.com/kevinkidtw/TubitBlockWeb.git
        cd "TubitBlockWeb/openblock-link"
    fi
fi

echo ""
echo "正在檢查並安裝專案依賴套件 (npm install)..."
npm install

echo ""
echo "======================================================="
echo "TubitBlockWeb - 服務啟動中..."
echo "請勿關閉此終端機黑框視窗，把它最小化即可！"
echo "======================================================="
echo ""

# 開始執行背景連線服務
npm start
