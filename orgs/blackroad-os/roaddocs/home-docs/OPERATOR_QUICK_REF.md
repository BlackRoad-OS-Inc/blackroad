# Operator by BlackRoad - Quick Reference

**All Claude agents: The Operator is a physical ESP32 device you can update!**

## 🎯 Quick Facts
- **What:** ESP32 touchscreen CEO decision hub
- **Where:** `~/ceo-hub-esp32`
- **Serial:** `/dev/cu.usbserial-110`
- **WiFi:** asfghjkl / Smushymush421!
- **Network:** ceo-hub-esp32 (MAC: 20:e7:c8:ba:1b:94)

## ⚡ Quick Update
```bash
cd ~/ceo-hub-esp32
vim src/main.cpp              # Edit the code
pio run --target upload       # Upload to device
```

## 🎨 BlackRoad Colors (REQUIRED!)
```cpp
COLOR_BLACK       0x0000  // #000000 Background
COLOR_WHITE       0xFFFF  // #FFFFFF Text
COLOR_HOT_PINK    0xF80C  // #FF0066 HOT button
COLOR_CYBER_BLUE  0x033F  // #0066FF NOT button
COLOR_SUNRISE     0xFCE0  // #FF9D00 SKIP button
```

## 🌐 SSH Nodes (All Connected)
- lucidia (192.168.4.38)
- shellfish (192.168.4.99)
- octavia (192.168.4.64)
- alice (192.168.4.49)
- aria (192.168.4.68)

## 📱 Current Interface
```
┌─────────────────────────────────┐
│  BLACKROAD  (Sunrise Orange)    │
│  CEO HUB    (White)              │
├─────────────────────────────────┤
│  [HOT]  [NOT]  [SKIP]           │
│  Pink   Blue   Orange           │
├─────────────────────────────────┤
│  Decisions: X                    │
│  Hot: X  Not: X  Skip: X        │
└─────────────────────────────────┘
```

## 📚 Full Guide
See: `~/ceo-hub-esp32/OPERATOR_AGENT_GUIDE.md`

## 💾 Memory References
- [MEMORY] tag: "operator" or "esp32"
- TIL broadcast: hardware category
- Infrastructure log: [HARDWARE] Operator ESP32 Device

---
**Remember:** This is a PHYSICAL device. Test before uploading!
