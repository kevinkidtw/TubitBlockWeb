# TubitBlock Web 版除錯歷史與修復紀錄 (Debug History)

這份文件整合了將 OpenBlock 桌面版移植到純網頁版本 (Web + 本地伺服器) 過程中所遭遇的所有核心報錯資訊與修復方案。

## 1. 專案解析載入崩潰 (Project Parse Crash)

* **報錯訊息**: `Error: Non-ascii character in FixedAsciiString` 和 `Cannot read properties of undefined (reading 'length')`
* **發生原因**: Web 版本的 Blockly 初始化一個完全空白的專案時，缺少了官方 Scratch 3.0 (SB3) 必需的後設資料 (如 `monitors`, `extensions`)。這導致預設 `loadProject` 驗證失敗，VM 錯誤地退回使用舊版 Scratch 1.0 (SB1) 二進位解析器去解析 JSON，從而引發型別崩潰。
* **修復方式**: 在 `electron-shim.js` 中實作了猴子修補 (Monkey Patch)，攔截 `vm.loadProject`。遇到標準 JSON 字串時強制繞過 Schema 驗證而直接呼叫 `vm.deserializeProject()`，順利掛載空白專案。

## 2. 設備圖示雙重路徑錯誤 (Double Icon Pathing)

* **報錯訊息**: 尋找圖示失敗，網路請求顯示 `http://localhost:8080/www/external-resources/external-resources/devices/TUBITV2/assets/TUBITV2.png 404 Not Found`
* **發生原因**: 桌面版的設備列表 API 原本會動態拼接 Resource Server 的位址。我們靜態化的 `zh-tw.json` 如果直接保留了 `external-resources/` 前綴，經過 `electron-shim.js` 的 `fetch` 攔截器再次疊加，就會導致路徑重複。
* **修復方式**: 移除了 `zh-tw.json` 中內建與外部設備的圖示 URL 前綴，並優化了 `electron-shim.js` 的正則替換邏輯，遇到前方已有 `external-resources/` 則去重。

## 3. 擴充套件積木圖示遺失 (Missing Extension Icons)

* **報錯訊息**: 左側擴充套件分類顯示預設的黃色圓圈，並且開發工具 (Console) 持續報錯 `Failed to decode downloaded font` 或是 base64 亂碼錯誤。
* **發生原因**:
    1. Base64 錯誤是 Webpack 載入機制在處理 Source Map 時產生的干擾警告，不影響邏輯。
    2. 真實原因是硬體擴充設定的 `toolbox.js` 未包含 XML `iconURI` 屬性。在桌面版中此屬性由後端邏輯注入，在 Web 版中被省略了。
* **修復方式**: 撰寫 Node 腳本，從 `zh-tw.json` 讀取並動態將相對應的 `iconURI="../external-resources/..."` 寫死注入所有 66 個設備的 `toolbox.js` 標籤中。同時修改 `electron-shim.js` 的攔截器加入動態 `?t=timestamp` 破除瀏覽器開發伺服器的記憶體快取。

## 4. C++ 韌體編譯時找不到函式庫 (Arduino Builder Missing Library Error)

* **報錯訊息**: `fatal error: TuBitCore.h: No such file or directory` (或類似的其他擴充感測器函式庫報錯)
* **發生原因**: 桌面版在啟動或掛載擴充套件時，擁有作業系統權限會自動將 `external-resources/extensions/<擴充名>/lib/` 內的所有專屬函式庫拷貝到 Arduino 編譯器底下 (`openblock-link/tools/Arduino/libraries/`)。網頁版前端無法執行此搬移動作。
* **修復方式**: 撰寫專屬的 Python 部署腳本，一次性從 `external-resources` 掃描，將所有第三方及硬體客製化的函式庫資料夾，全部複製貼上到 OpenBlock Link 的 Arduino libraries 目錄中，解決了所有的依賴缺失問題。
