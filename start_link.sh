#!/bin/bash

# 切換到 openblock-link 目錄
cd "$(dirname "$0")/openblock-link"

echo "TubitBlockWeb - 正在啟動硬體連線助手 (Mac/Linux)..."
echo "請勿關閉此黑框視窗，最小化即可！"

# 開始執行背景連線服務
npm start
