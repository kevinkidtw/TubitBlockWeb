# TubitBlock 開放原始碼積木程式教育平臺

TubitBlock 是一個基於網頁的視覺化積木程式設計平臺，專為學生與教師設計，支援多種硬體設備（如 TU:bit、ESP32、Arduino 等）的程式編寫與線上燒錄。

## 💡 系統架構簡介

為了讓大家能「**隨時隨地打開瀏覽器就能寫程式**」，同時又保留「**將程式碼燒錄進實體硬體**」的強大功能，本系統分為「雲端網頁版」與「本地電腦端」兩個部分：

1. **網頁前端介面 (TubitBlock Web)**：
   - 包含你所看到的所有積木、舞台與操作介面。
   - 它可以免費架設在網頁伺服器（如 GitHub Pages 或學校伺服器）上。學生只要有網址就能打開，完全不需要安裝龐大的應用程式。
2. **硬體連線助手 (OpenBlock Link)**：
   - 瀏覽器基於安全性考量，無法直接控制你插在電腦 USB 上的開發板。
   - 因此，我們提供了一個名為 `openblock-link` 的輕量背景啟動程式。學生只需在自己的電腦上開啟它，它就會像橋樑一樣，負責將網頁上的積木轉換為 C++ 程式碼，並安全地燒錄進你的硬體中。

---

## 👩‍🎓 學生與一般使用者教學 (本機連線準備)

如果你只是要「寫程式並燒錄到板子上」，請在你的電腦完成以下一次性的環境準備：

### 第一步：安裝 Node.js (執行環境)

硬體連線助手依賴 Node.js 環境運行。如果你的電腦還沒安裝過，請先完整安裝：

- **Windows 使用者**：
    1. 前往 [Node.js 官方網站](https://nodejs.org/)。
    2. 下載並安裝標有 **"LTS" (長期維護版)** 的 Windows 安裝檔 (`.msi`)。
    3. 執行下載的檔案，安裝過程中一直點擊「下一步」即可（建議保持所有預設選項）。
- **Mac 使用者**：
    1. 同樣前往 [Node.js 官方網站](https://nodejs.org/) 下載 **LTS** 版本的 `.pkg` 安裝檔並執行安裝。
    2. （進階：熟悉終端機的使用者，也可使用 Homebrew 安裝：打開終端機輸入 `brew install node`）。

### 第二步：下載並執行硬體連線助手

1. 請在本頁面右上角點擊綠色按鈕 **`<> Code`**，選擇 **`Download ZIP`** 下載整個專案並解壓縮。（若你的電腦已經安裝 Git，也可以直接下載啟動腳本，它會自動幫你執行 `git clone`）。
2. 開啟解壓縮後的資料夾，你會看到專為不同系統準備的智慧型「一鍵啟動腳本」。這個腳本會**自動檢查你是否安裝好 npm 工具**，並自動定位與開啟連線軟體：
   - **Windows 使用者**：直接連按兩下執行 **`start_link.bat`**。
   - **Mac 使用者**：打開終端機，將 **`start_link.sh`** 拖曳到終端機內並按下 Enter，或者輸入指令 `./start_link.sh`。（若遇到權限問題，請先執行 `chmod +x start_link.sh`）。

*(如果彈出黑框視窗顯示「找不到 Node.js (npm)」，請回到第一步安裝 Node.js。若顯示「正在啟動硬體連線助手」，且視窗沒有立刻關閉，代表成功啟動！**請保持這個黑色的文字視窗開啟，不要關掉它，把它最小化即可。**)*

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

4. 現在，只要讓學生打開瀏覽器連線至 `http://<您的伺服器IP>:8080/www/index.html` 即可看見介面。（注意：學生自己的電腦端依然要執行前面教學的 `openblock-link` 背景程式才能燒錄硬體）。

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
   - 本機部署時，請務必將該函式庫資料夾放入 `openblock-link/tools/Arduino/libraries/` 目錄下。如此一來，學生在網頁端點擊「上傳」時，背景的 Arduino 編譯器才能正確找到並編譯你的客製化感測器驅動程式。

---

*開發筆記：若在上述修改或遷移過程遭遇破圖、連線失敗、專案無法開啟等問題，請查閱原始目錄下的 `Debug_History.md` 避坑手冊。*
