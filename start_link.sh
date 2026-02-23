#!/bin/bash

echo "TubitBlockWeb - 正在啟動硬體連線助手 (Mac/Linux)..."
echo "正在檢查系統環境..."

# 檢查 npm 是否安裝
if ! command -v npm &> /dev/null
then
    echo "======================================================="
    echo "[錯誤] 找不到 Node.js (npm)！"
    echo "硬體連線助手需要 Node.js 才能運行。"
    echo "請先前往官方網站下載並安裝 LTS 版本：https://nodejs.org/"
    echo "安裝後請重新開啟終端機，並再次執行此腳本。"
    echo "======================================================="
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$SCRIPT_DIR/openblock-link" ]; then
    cd "$SCRIPT_DIR/openblock-link"
elif [ -d "$SCRIPT_DIR/TubitBlockWeb/openblock-link" ]; then
    cd "$SCRIPT_DIR/TubitBlockWeb/openblock-link"
else
    echo "找不到 openblock-link 目錄，準備透過 Git 自動下載專案..."
    if ! command -v git &> /dev/null
    then
        echo "[錯誤] 找不到 git 程式，無法自動下載專案！"
        echo "請先安裝 Git，或直接從 GitHub 首頁下載 ZIP 壓縮包。"
        exit 1
    fi
    cd "$SCRIPT_DIR"
    git clone https://github.com/kevinkidtw/TubitBlockWeb.git
    cd "TubitBlockWeb/openblock-link"
fi

echo ""
echo "TubitBlockWeb - 服務啟動中..."
echo "請勿關閉此終端機黑框視窗，最小化即可！"
echo ""

# 開始執行背景連線服務
npm start
