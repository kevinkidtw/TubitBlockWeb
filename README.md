# TubitBlock Web Edition

這是將 OpenBlock 桌面版 (Desktop) 邏輯完全抽離，移植而成的純網頁版本。它移除了 Node/Electron 相關的底層綁定，使你能夠直接透過瀏覽器進行硬體積木的開發與韌體燒錄。

## 系統架構理念 (Architecture)

為了突破瀏覽器固有的安全性沙盒限制（無法讀寫使用者的電腦檔案系統），本專案採用了雙伺服器架構：

1. **靜態網頁伺服器 (Static Web Server)**：負責伺服 `/www/` 目錄下的前端 React 介面、積木定義，以及 `/external-resources/` 下的所有靜態資源（包括裝置清單、擴充圖示、本地化語系檔）。
2. **OpenBlock Link 背景服務 (Local Daemon)**：在背景透過 Node.js 運行於 port 20111。它擁有完整的作業系統權限，因此負責：
   - 掃描 USB 序列埠 (Serial Ports)
   - 執行與呼叫 Arduino Builder (位於 `/openblock-link/tools/Arduino/`) 來編譯你所生成的 C++ 原始碼
   - 使用 esptool 或 avrdude 等工具將編譯好的韌體 (`.bin`) 燒錄至硬體裝置 (例如 ESP32, Arduino Uno, TU:bit 等)

## 快速啟動指南 (Quick Start)

請同時啟動上述的兩個伺服器，方可獲得完整體驗。

### 步驟 1：啟動靜態網頁伺服器

打開終端機，導航至專案根目錄 (`TubitBlockWeb版`)，並使用 Python 內建的 HTTP 伺服器：

```bash
# 在 Mac/Linux 上
python3 -m http.server 8080 -d ./

# 在 Windows 上
python -m http.server 8080 -d ./
```

啟動後，網頁介面將可於 `http://localhost:8080/www/` 存取。

### 步驟 2：啟動 OpenBlock Link 背景服務

開啟第二個終端機視窗，進入 `openblock-link` 目錄，然後啟動 Node 服務：

```bash
cd openblock-link
npm start
```

這將在背景啟動 WebSocket 服務。此時你隨時可以在網頁版的左下角點擊「增加設備」，並順利與插入電腦的開發板連線與上傳韌體。

---

## 常見問題與除錯 (FAQ & Debugging)

若您在開發過程中遇到設備清單遺失、積木圖示消失或 Arduino 編譯找不到函式庫等問題，請參閱同目錄下的 `Debug_History.md`，裡面詳細記錄了桌面版向 Web 版轉移過程中所有的已知坑洞與解法。

- **圖示未更新**：專案靜態資源的快取已經透過 `electron-shim.js` 動態時間戳解決。
- **編譯器缺少擴充函式庫**：我們已預先注入 `TuBitCore` 與其他 60+ 種感測器函式庫。若未來有新增的第三方自製硬體擴充，請務必手動將其 `.zip` 解壓縮後，放入 `openblock-link/tools/Arduino/libraries/` 資料夾內，方可成功編譯。
