# TubitBlock 開放原始碼積木程式教育平臺

TubitBlock 是一個基於網頁的視覺化積木程式設計平臺，專為學生與教師設計，支援多種硬體設備（如 TU:bit、ESP32、Arduino 等）的程式編寫與線上燒錄。

## 💡 系統架構簡介

為了讓大家能「**隨時隨地打開瀏覽器就能寫程式**」，同時又保留「**將程式碼燒錄進實體硬體**」的強大功能，本系統分為「雲端網頁版」與「本地電腦端」兩個部分：

1. **網頁前端介面 (TubitBlock Web)**：
   - 包含你所看到的所有積木、舞台與操作介面。
   - 它可以免費架設在網頁伺服器（如 GitHub Pages 或學校伺服器）上。學生只要有網址就能打開，完全不需要安裝龐大的應用程式。
2. **硬體連線助手 (TUbitBlock Link)**：
   - 瀏覽器基於安全性考量，無法直接控制你插在電腦 USB 上的開發板。
   - 因此，我們提供了一個名為 `tubitblock-link` 的輕量背景啟動程式。學生只需在自己的電腦上開啟它，它就會像橋樑一樣，負責將網頁上的積木轉換為 C++ 程式碼，並安全地燒錄進你的硬體中。

---

## 👩‍🎓 學生與一般使用者教學 (本機部署流程)

為了讓瀏覽器能連接到您的實體硬體版，您需要在自己的電腦上準備好「硬體連線助手」。我們已經為您準備了一個全自動的「一鍵啟動腳本」，它會主動幫您把缺少的元件（Node.js / 官方安裝檔 / 驅動模組等）全部下載並安裝到好！

### ⚡ 推薦方式：使用一鍵啟動腳本自動部署

1. 請直接下載本專案提供的一鍵啟動腳本（不需下載幾百MB的整個專案）。**⚠️ 非常重要：請勿直接在 GitHub 網頁上按右鍵另存，否則會載到無效的網頁原始碼。請務必使用以下正確方式下載**：
   - **Windows 使用者**：[點擊此 Raw 連結 (start_link.bat)](https://raw.githubusercontent.com/kevinkidtw/TubitBlockWeb/main/start_link.bat) 打開純文字畫面後，按鍵盤 `Ctrl + S` 存檔；或對連結點選右鍵「另存連結為...」。
   - **Mac 使用者**：[點擊此 Raw 連結 (start_link.sh)](https://raw.githubusercontent.com/kevinkidtw/TubitBlockWeb/main/start_link.sh) 打開純文字畫面後，按鍵盤 `Cmd + S` 存檔；或對連結點選右鍵「下載連結檔案」。
2. （僅Mac需要）打開終端機，為下載的檔案增加執行權限：輸入 `chmod +x start_link.sh`。
3. 執行您下載的腳本：
   - **Windows 使用者**：直接連按兩下 `start_link.bat`。
   - **Mac 使用者**：在終端機內輸入 `./start_link.sh`，或者將檔案拖曳進終端機後按下 Enter。
4. **全自動執行階段**：
   - 腳本會先自動掃描您的電腦。如果還沒安裝過 Node.js，電腦會自動啟動軟體執行標準安裝（系統可能會詢問授權管理員權限）。
   - 若您是第一次執行（電腦還沒有專案原始碼），腳本將自動連線 GitHub 把 1.5GB 的硬體編譯函式庫打包拉下來並解壓縮。
   - 最後自動執行 `npm install` 並開始執行連線服務。
5. *(注意：如果跳出「Node.js 安裝成功」的提示，系統通常需要載入新的環境變數，請關閉黑框視窗後再執行一次腳本。)*
6. 最終啟動成功後，黑框會停在畫面。**請保持這個黑色的文字視窗開啟，不要關掉它，把它最小化即可。**

---

### 🗃 替代方式：手動下載原始碼部署（供參考用）

如果您所在的網路環境不允許腳本直接下載程式碼，或者您想自行調整檔案，您也可以遵循以下傳統的手動步驟：

1. **手動安裝 Node.js**：如果腳本無法自動安裝，請自行前往 [Node.js 官方網站](https://nodejs.org/) 下載並安裝 **LTS (長期維護版)**。
2. **手動下載專案壓縮包**：在本頁面右上角點擊綠色按鈕 **`<> Code`**，選擇 **`Download ZIP`** 下載整個專案，並解壓縮到您的電腦上。
3. **開啟終端機/命令提示字元並啟動**：
   使用 `cd` 指令進入解壓縮後的 `tubitblock-link` 資料夾。例如 `cd Desktop\TubitBlockWeb-main\tubitblock-link`。
   接著依序輸入 `npm install` 以及 `npm start` 讓它在背景執行。

### 第三步：開啟網頁寫程式

點擊老師提供的網址（如果是使用 GitHub Pages，網址通常長這樣：`https://你的帳號.github.io/TubitBlockWeb/www/index.html`）。

現在，你可以在網頁左下角點擊「增加設備」，網頁就能順利掃描到你的 USB 開發板並進行連線了！

---

## 👨‍🏫 教師與進階開發者指南

如果你是學校的資訊組長、老師，想為學生部署專屬的教學環境，或自行客製化增加學校特有的感測器積木：

### 🚀 選項一：將網頁介面免費部署至 GitHub Pages

利用 GitHub Pages，你可以免費且零維護成本地讓全校學生存取這個平臺。

1. 將本專案 **Fork（複製）** 到你自己的 GitHub 帳號下。
2. 進入專案根目錄，確認有一個名為 `.nojekyll` 的隱藏檔案。（這是為了防止 GitHub 使用預設的 Jekyll 引擎解析龐大的 Arduino 原始碼而停機崩潰。如果沒有，請手動新增一個完全空白的同名檔案）。
3. 到專案的 **Settings** -> 左側欄 **Pages**。
4. 在 **Build and deployment** 區塊：
   - Source 選擇 `Deploy from a branch`
   - Branch 選擇 `main`，資料夾選擇 `/ (root)`，並點擊 `Save`。
5. 等待數分鐘後，GitHub 會為你生成專屬網址，學生只需訪問 `https://<你的帳號>.github.io/<專案名稱>/www/index.html` 即可。

### 🐧 選項二：自行架設伺服器 (Linux 教學示範)

若學校有內部網路限制或自架需求，你可以將 `/www` 與 `/external-resources` 放置於任何靜態網頁伺服器（例如 Nginx 或 Apache）。
以下為最新 Ubuntu/Debian 系統使用 Python 簡易啟動的示範：

1. **更新環境並安裝 Python3 與 Git**：

   ```bash
   sudo apt update
   sudo apt install python3 git -y
   ```

2. **下載專案原始碼**：

   ```bash
   git clone https://github.com/kevinkidtw/TubitBlockWeb.git
   cd TubitBlockWeb
   ```

3. **啟動靜態伺服器** (使用 Port 8080 作為示範)：

   ```bash
   nohup python3 -m http.server 8080 -d ./ > server.log 2>&1 &
   ```

4. 現在，只要讓學生打開瀏覽器連線至 `http://<您的伺服器IP>:8080/www/index.html` 即可看見介面。（注意：學生自己的電腦端依然要執行前面教學的 `tubitblock-link` 背景程式才能燒錄硬體）。

### 🛠 教學資源擴充：如何新增硬體設備與感測器？

TubitBlock 強大的地方在於極高的客製化彈性。若要新增學校獨有的感測器積木：

1. **設定裝置清單 (`zh-tw.json`)**：
   - 路徑：`external-resources/devices/zh-tw.json`。
   - 此檔案控制了學生在點擊「新增設備」時看到的清單。若要新增選項，請依照 JSON 格式在此處註冊新的硬體名稱與基礎介紹。
2. **擴充介面與積木邏輯 (`toolbox.js` 與 `blocks.js`)**：
   - 在 `external-resources/extensions/` 目錄下建立新資料夾。
   - `toolbox.js`：定義左側積木抽屜的分類，**務必確保 `<category>` 標籤中包含 `iconURI` 屬性**（例如 `iconURI="../external-resources/extensions/新擴充/assets/icon.png"`），否則網頁版的積木抽屜圖示會破圖變成空白氣泡。
   - `blocks.js`：定義視覺積木的形狀與顏色。
   - `generator.js`：定義該積木拉接後，要產生什麼樣的 C/C++ 程式碼。
3. **補充 Arduino 第三方函式庫 (非常重要)**：
   - 若你的感測器會 `#include <某某Library.h>`，你必須將這個第三方 C++ 函式庫夾帶在專案中。
   - 本機部署時，請務必將該函式庫資料夾放入 `tubitblock-link/tools/Arduino/libraries/` 目錄下。如此一來，學生在網頁端點擊「上傳」時，背景的 Arduino 編譯器才能正確找到並編譯你的客製化感測器驅動程式。

---

## 📝 近期重要更新紀錄 (Changelog)

- **OS-Specific 編譯工具鏈自動下載**：全面升級了 `start_link.sh` (Mac/Linux) 與 `start_link.ps1` (Windows) 啟動腳本。現在腳本會自動偵測使用者的作業系統與 CPU 架構（支援 macOS ARM64 / Intel、Windows x64、Linux x86_64），並從 GitHub Releases 按需下載對應的 6 個 ESP32 編譯器工具，避免儲存庫過於龐大，徹底解決跨平臺相容性問題。
- **專案瘦身與清理**：清理了 1GB 以上的舊版工具包壓縮檔（如過期的 `openblock-tools-darwin-x64-v2.11.1.7z`），並移除了殘留的日誌與空目錄，完善了 `.gitignore`，將專案體積大幅縮小。
- **TUbitBlock 全面更名與品牌重塑**：將全專案超過 80 個檔案內的歷史 `openblock` 參考全面更名為 `tubitblock`。包含主目錄重命名為 `tubitblock-link`、更新環境變數 (`.tubitblockData`)、修改 Arduino C++ 擴充函式庫檔名。針對無法手動修改的 webpack 編譯產物，則創新地利用 `electron-shim.js` 加入 `MutationObserver` 進行瀏覽器端動態 DOM 文字修補。
- **一鍵啟動腳本包含靜態伺服器**：修復了網頁版找不到擴展圖片的 404 問題。啟動腳本現在會完整建立本地的全端環境，包含啟動 HTTP 靜態檔案伺服器 (Port 8080) 與 WebSocket 通訊服務 (Port 20111)。

---

*開發筆記：若在上述修改或遷移過程遭遇破圖、連線失敗、專案無法開啟等問題，請查閱原始目錄下的 `Debug_History.md` 避坑手冊。*
