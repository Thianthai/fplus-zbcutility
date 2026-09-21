# ZBCUTILITY — Object List

`⬜` ยังไม่สร้าง · `🟨` ส่ง code แล้วรอสร้าง · `🟦` activate แล้วรอ push · `✅` อยู่ใน repo

| Object | Type | ไฟล์ | ผู้ใช้ | Status |
|---|---|---|---|---|
| `ZBCUTILITY` | Package | `src/package.devc.xml` | — | ✅ baseline `090520a` (`/src/` · FULL) |
| `ZBC_SFDC_TOKEN_REST` | Outbound Service (SCO3) — HTTP → `/services/oauth2/token` | `src/zbc_sfdc_token_rest.sco3.xml` | ทุก RICEFW ที่ยิง SFDC | ⬜ |
| `ZCS_SFDC_TOKEN` | Communication Scenario outbound · **Basic** (user = client id · pw = secret ใน `SFDC_DEV`) | `src/zcs_sfdc_token.sco1.xml` | | ⬜ |
| Communication Arrangement `ZCA_SFDC_TOKEN` | Fiori config × `SFDC_DEV` — ไม่ขึ้น git | — | | ⬜ |
| `ZCL_UTILITY` | Class — `get_sfdc_token( )` · `parse_sfdc_token_response( )` (pure) | `src/zcl_utility.clas.abap` | ZARE002 · ZARI002 | 🟦 shell เปล่าอยู่บน tenant แล้ว (`090520a`) รอ method |
| `ZCL_UTILITY` testclasses | parse token / error response — ไม่ต่อ SFDC | `src/zcl_utility.clas.testclasses.abap` | | ⬜ |

## ผู้เรียกที่ต้องปรับ

| RICEFW | class | สถานะ |
|---|---|---|
| ZARE002 | `ZCL_ZARE002_SFDC_RESULT` — `send` / `check_connection` ใส่ Bearer จาก `get_sfdc_token` | ⬜ (Phase 8C.8) |
| ZARI002 | `ZCL_ZARI002_SFDC_NOTIFY` — เหมือนกัน | ⬜ นอก scope ZARE002 |
