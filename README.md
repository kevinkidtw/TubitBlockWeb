# TUbitBlock 開放原始碼積木程式教育平臺

TUbitBlock 是一個專為各級學校資訊教育設計的進階視覺化積木程式開發環境。本系統支援 TU:bit、ESP32、Arduino 等多種開源硬體，能有效解決傳統開發環境安裝繁瑣、版控困難以及跨平台不相容的問題，非常適合應用於 108 課綱下的物聯網與運算思維課程。

## 💡 系統架構簡介

為符合校園情境中「**隨開即用、集中管理**」的核心需求，又能保留**實體硬體燒錄**的底層控制力，系統採前後端分離架構設計：

1. **雲端/區域網路前端 (TUbitBlock Web)**：
   - 負責所有積木邏輯、視覺化編輯器與流程控制。
   - 支援將靜態檔案部署於校內伺服器（Nginx/Apache）或免費的 GitHub Pages。跨班級、跨電腦教室上課時，學生僅需具有瀏覽器及對應網址即可進行程式開發，實現真正的零客戶端安裝 (Zero-install Client)。
2. **本機硬體連線代理 (TUbitBlock Link)**：
   - 解決現代瀏覽器基於 WebUSB / Web Serial 安全限制，無法完整支援複雜驅動與編譯鏈的問題。
   - 為一支常駐於學生端電腦（或廣播派送映像檔中）的輕量級 Node.js 服務 (`tubitblock-link`)。負責接收前端的 WebSocket 編譯請求、呼叫本機 C++ 工具鏈 (esp-idf / arduino-cli) 進行編譯，並過渡至 USB 序列埠完成燒錄程序的自動化管線。

---

## 👩‍🎓 學生與一般電腦教室配置 (終端部署流程)

為減輕資訊組長或任課教師在電腦教室的環境派送負擔，本專案提供具有「環境偵測與自動修復」能力的整合性啟動腳本。此腳本支援透過網管軟體（如廣播系統的遠端執行功能）進行批次派送與初始化。

### ⚡ 推薦方式：使用一鍵啟動腳本自動部署

此階段建議於學期初或電腦教室映像檔（Image）製作階段執行：

1. 請取得本專案專為自動化部署設計的啟動腳本，可透過指令或瀏覽器下載：
   - **Windows 教室**：[start_link.bat (Raw 連結)](https://raw.githubusercontent.com/kevinkidtw/TubitBlockWeb/main/start_link.bat) (可整合至開機啟動或桌面捷徑)
   - **Mac/Linux 教室**：[start_link.sh (Raw 連結)](https://raw.githubusercontent.com/kevinkidtw/TubitBlockWeb/main/start_link.sh)
2. （僅 macOS / Linux 需要）賦予執行權限：`chmod +x start_link.sh`。
3. 執行腳本以啟動環境初始化流程：
   - **Windows 環境**：執行 `start_link.bat`。
   - **Mac/Linux 環境**：執行 `./start_link.sh`。
4. **初始化與依賴解析階段 (自動執行)**：
   - **環境檢測**：腳本將檢查系統是否具備 Node.js (npm) 環境。若無，將觸發官方靜態安裝包的下載與靜默安裝。
   - **編譯鏈按需下載 (On-Demand Fetching)**：腳本會辨識終端機的 OS 與 CPU 架構設定（如 Windows x64 或 Mac ARM64），並從遠端伺服器僅拉取所需的 ESP32 / Arduino 跨平臺工具鏈，避免不必要的頻寬消耗。
   - **依賴構建**：自動執行 `npm install` 並綁定 WebSocket 通訊埠 (Port 20111)。
5. *(注意：若環境為首次安裝 Node.js，需重新載入系統環境變數 (`PATH`)，請關閉該終端機視窗並重新執行腳本。)*
6. 服務成功掛載後，將於背景維持 WebSocket Listen 狀態。此視窗可最小化，為確保硬體通訊正常，上課期間請勿強制終止該進程。

---

## 🗃 替代方式：手動下載原始碼部署（供進階除錯參考）

若校安網路環境 (例如防火牆/Proxy) 阻擋了腳本的自動封包下載，資訊人員可採取離線/手動配置模式：

1. **基礎環境建置**：自行部署 Node.js (建議採用 LTS 長期維護版本) 至所有終端機。
2. **原始碼獲取**：由本 GitHub 儲存庫下載 `.zip` 壓縮包，並解壓至統一的終端路徑（例如 `C:\TUbitBlock\` 或透過網碟掛載）。
3. **服務啟動**：
   開啟命令提示字元 (CMD/Terminal)，切換至 `tubitblock-link` 目錄，執行：

   ```bash
   npm install
   npm start
   ```

### 第三步：開啟網頁寫程式

1. 請學生透過瀏覽器連線至學校統一佈署的前端網址（例如：`http://校內伺服器IP:8080/www/index.html` `https://校名.github.io/TubitBlockWeb/www/index.html`）。
2. 在網頁左下角點擊「增加設備」，前端會透過 WebSocket (`ws://127.0.0.1:20111`) 與本機的 Link 服務握手，即可偵測到連接於 USB 的開發板並開始教學。

---

## 👨‍🏫 資訊教師與伺服器管理員指南

如果您是學校的資訊組長或系統管理員，規劃為全校建置統一的存取入口或加入自製感測器模組：

### 🚀 選項一：將網頁介面免費部署至 GitHub Pages

這項方案能大幅節省校內伺服器的建置與維護成本，並具備高防護力與 CDN 負載平衡優勢。

1. 以學校科室或個人帳號將本專案 **Fork**。
2. 確認專案根目錄下存在 `.nojekyll` 隱藏檔（此設定可防止 GitHub Pages 的 Jekyll 解析器忽略底層的 `_` 系統資料夾，避免編譯器資源載入失敗）。
3. 進入 GitHub 專案的 **Settings** -> 左側選單 **Pages**。
4. 於 **Build and deployment** 設定區：
   - Source: `Deploy from a branch`
   - Branch: `main`，路徑選擇 `/ (root)`，儲存設定。
5. 部署完成後，將生成的靜態網址（如 `https://<帳號>.github.io/<專案>/www/index.html`）掛載於學校數位學習平台即可供學生使用。

### 🐧 選項二：自行架設伺服器 (Linux 伺服器建置示範)

對於需要受控於學術網路內、或無對外網路連線的電腦教室，建議採取內部伺服器托管方案：

1. **環境整備** (以 Ubuntu/Debian 為例)：

   ```bash
   sudo apt-get update
   sudo apt-get install python3 git -y
   ```

2. **拉取專案至伺服器 `/var/www` 或使用者目錄**：

   ```bash
   git clone https://github.com/kevinkidtw/TubitBlockWeb.git
   cd TubitBlockWeb
   ```

3. **啟動 Web 伺服器** (示範使用 Python 輕量 http.server，企業級建議配置 Nginx/Apache 指向此目錄)：

   ```bash
   nohup python3 -m http.server 8080 -d ./ > server.log 2>&1 &
   ```

4. 學生端只需連線至 `http://<內部伺服器IP>:8080/www/index.html` 即可載入開發環境。（註：終端機仍需執行 `TUbitBlock Link` 服務以處理實體 I/O 與編譯）。

### 🛠 教學資源擴充：如何新增硬體設備與感測器？

TUbitBlock 開放式的架構設計，允許任課教師因應特定專題或校訂課程，無縫繼承並擴充第三方感測器支援：

1. **註冊設備定義 (`zh-tw.json`)**：
   - 位置：`external-resources/devices/zh-tw.json`。
   - 此檔案管理前端設備庫的註冊表，新增的感測器套件必須依循 JSON 綱要 (Schema) 定義設備名稱與描述。
2. **擴充積木介面與轉換邏輯 (`toolbox.js` 與 `blocks.js`)**：
   - 於 `external-resources/extensions/` 建立套件專屬目錄。
   - `toolbox.js`：定義分類抽屜（需確保 `<category>` 包含 `iconURI` 避免渲染失敗）。
   - `blocks.js`：建構視覺積木的型態與 I/O 接口 (Type & Connection)。
   - `generator.js`：實作該積木對應的 AST 至 C/C++ 語法轉換邏輯。
3. **整合 Arduino C/C++ 標頭檔與依賴 (關鍵環節)**：
   - 若客製化積木使用了第三方硬體函式庫（例如 `#include <Adafruit_Sensor.h>`），必須將該 Library 的實體原始碼包裹。
   - 請將函式庫資料夾放入 `tubitblock-link/tools/Arduino/libraries/` 目錄中。如此，後端的 Arduino Toolchain 才能在學生點擊「燒錄」時，正確解析標頭檔並完成 Linking 程序。

---

## 📝 版本更新紀錄 (Changelog)

### v0.85 (當前版本)

- **動態首字 SVG 圖示**：透過前端 DOM 攔截技術即時分析標籤，將主畫面左側「分類選單」的預設圖示替換為帶有分類中文首字 (如：多、機、馬、按) 的高畫質 SVG 動態色彩圓標，大幅減少圖片空間，視覺更一致。
- **擴充功能庫真實影像保留**：精確控制 DOM 攔截範圍，於「選擇擴充功能」彈出視窗保留硬體原廠之寫實照片，在保持左側選單視覺統一的同時，依舊提供清晰的硬體辨識度。

### v0.82

- **智慧部署腳本**：`start_link` 腳本全面升級，支援 Mac/Win/Linux，具備硬體架構感知能力，並能根據系統動態下載所需 ESP32 編譯元件。解決跨平臺相容性異常。
- **儲存庫巨幅精簡**：移除高達 3.7GB 冗餘靜態檔案與日誌，Git 儲存庫體積下降逾 60%，提升校安代理伺服器與終端機同步效率。
- **TUbitBlock 核心重構**：完成歷史 `openblock` 變數與底層通訊協定全面更名（含 `tubitblock-link` 與 `.tubitblockData`），並透過 `electron-shim.js` 動態修補前端 DOM。
- **本地伺服器整合與路由防護**：一鍵腳本同步掛載 HTTP 靜態服務 (Port 8080) 與 WebSocket (Port 20111)。建置全域 URL 攔截機制，將所有失效的舊版維基連結強制導回 `trgreat.com/tu-wiki/`。
