#!/bin/bash

# 檢查是否為 root 權限
if [ "$EUID" -ne 0 ]; then 
  echo "請以 sudo 執行此腳本"
  exit
fi

# ==========================================
# 1. 時區設定區塊
# ==========================================
TARGET_TZ="Asia/Hong_Kong"
echo "正在檢查系統時區..."

CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null)

if [ "$CURRENT_TZ" != "$TARGET_TZ" ]; then
    echo "發現目前時區為 ${CURRENT_TZ:-未設定}，正在切換至 $TARGET_TZ..."
    if command -v timedatectl &> /dev/null; then
        timedatectl set-timezone "$TARGET_TZ"
    else
        ln -sf "/usr/share/zoneinfo/$TARGET_TZ" /etc/localtime
        echo "$TARGET_TZ" > /etc/timezone
    fi
    echo "✅ 時區設定完成！"
else
    echo "✅ 系統時區已是 $TARGET_TZ，無需更改。"
fi

echo "----------------------------------------"

# ==========================================
# 2. 網路時間同步區塊 (突破憑證限制)
# ==========================================
echo "正在從 timeapi.io 獲取初始時間..."

URL="https://timeapi.io/api/time/current/zone?timeZone=$TARGET_TZ"
TIME_DATA=$(curl -s -k "$URL" | tr ',' '\n' | grep '"dateTime"' | cut -d '"' -f 4)

if [ -n "$TIME_DATA" ]; then
    echo "✅ 成功抓取時間: $TIME_DATA"
    date -s "$TIME_DATA" > /dev/null
    hwclock -w 2>/dev/null
    
    echo "🎉 初始時間同步完成！目前系統時間為: $(date)"
    echo "----------------------------------------"
    
    # ==========================================
    # 3. 安裝與設定 NTPsec 服務區塊
    # ==========================================
    echo "正在執行 apt update 並安裝 NTPsec 服務 (這可能需要幾十秒)..."
    
    # 因為時間已經正確，這裡的 apt update 不會遇到憑證過期的報錯
    apt-get update -qq
    
    # 改為安裝 ntpsec
    apt-get install -y ntpsec
    
    if [ $? -eq 0 ]; then
        echo "✅ NTPsec 套件安裝成功！"
        
        # 確保 NTPsec 服務設定為開機啟動並立即執行
        systemctl enable ntpsec 2>/dev/null
        systemctl start ntpsec 2>/dev/null
        
        echo "========================================"
        echo "🚀 全自動對時系統建置完畢！"
        echo "NTPsec 背景服務已接管，未來將自動保持毫秒級精準對時。"
        echo "========================================"
    else
        echo "❌ NTPsec 安裝失敗，請檢查網路連線或 apt 來源設定。"
    fi

else
    echo "❌ 錯誤：無法連線至 timeapi.io，已中斷後續 NTPsec 安裝程序。"
fi
