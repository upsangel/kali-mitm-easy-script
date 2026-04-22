# Kali MITM Easy Script

這是一個用於在 Kali Linux 上快速部署與管理 SSL MITM（中間人流量截取）的自動化腳本工具包。本專案旨在簡化繁雜的網橋設定、時間同步與 iptables 規則，讓你能夠專注於網絡流量的分析與安全測試。

## 🔍 什麼是 SSL MITM？
SSL MITM（Man-In-The-Middle）即「SSL 中間人攔截」。現代網絡大多採用 HTTPS 加密傳輸，傳統的抓包方式無法直接讀取內容。MITM 技術透過在客戶端與目標伺服器之間充當代理節點，並向客戶端動態派發偽造的 SSL 憑證，藉此將加密的流量解密（以供攔截與分析），然後再重新加密發送給伺服器。這對於 IoT 設備分析、App 網絡除錯及安全審計非常有用。

---

## 🚀 快速開始與使用步驟

### 1. 建立 Kali Live USB with Persistence
為了確保你的系統環境、安裝的套件與腳本設定在重啟後不會遺失，請務必製作具備 **Persistence（持續性儲存）** 功能的 Kali Linux Live USB。
* 🎥 **教學影片參考**：[Kali Linux 開機碟製作教學](https://www.youtube.com/watch?v=C79kSCVcghk) / [Kali Linux USB persistence the right way](https://www.youtube.com/watch?v=Hxau-bh8gr4)

### 2. 校準系統時間 (`sync_time.sh`)
進入 Kali 系統後，第一步請執行時間同步腳本(下載脚本請先執行 chmod +x *.sh 或其他方法賦予脚本執行權限)：
```bash
sudo ./sync_time.sh
```
**💡 為什麼這很重要？**
SSL/TLS 憑證的安全機制對時間極度敏感。如果你的 Kali 系統時間不正確，偽造出來的 SSL 憑證會被客戶端設備判定為「尚未生效」或「已過期」而直接拒絕連線，導致無法成功攔截流量。

### 3. 設置透明網關 (`setup_bridge.sh`)
接著，配置透明網關（Transparent Gateway）：
```bash
sudo ./setup_bridge.sh
```
此腳本會將你的 Kali 設備配置成一個網橋或路由節點。這意味著目標設備的網絡流量會在不知情的情況下，自動流經你的 Kali 系統，**完全不需要在目標設備上手動設定 Proxy**。

### 4. 啟動與關閉截取 (`Mitm_on` / `Mitm_off`)
網絡基礎設施準備好後，你可以隨時切換截取狀態：

* **開啟 MITM 攔截**：
  ```bash
  sudo ./mitm_ssl_on.sh
  ```
  這會自動配置 iptables 規則，將流經網關的 80 (HTTP) 與 443 (HTTPS) 流量劫持到代理監聽端口，並啟動 MITM PROXY 開始記錄與解析 SSL 數據。

* **關閉 MITM 攔截**：
  ```bash
  sudo ./mitm_ssl_off.sh
  ```
  測試完成後，執行此腳本會清除先前的 iptables 劫持規則並關閉代理程式，讓網絡流量恢復正常直連。

---

## ⚠️ 免責聲明
本專案提供的腳本與技術僅供**學術研究、網絡除錯與合法授權的安全測試**使用。請勿將其應用於未經授權的第三方設備或公共網絡。使用者須對自己的行為及可能引發的法律責任負完全責任。
