# ZBCUTILITY — Object List

`⬜` ยังไม่สร้าง · `🟨` ส่ง code แล้วรอสร้าง · `🟦` activate แล้วรอ push · `✅` อยู่ใน repo

| Object | Type | ไฟล์ | ผู้ใช้ | Status |
|---|---|---|---|---|
| `ZBCUTILITY` | Package | `src/package.devc.xml` | — | ✅ baseline `090520a` (`/src/` · FULL) |
| `ZBC_SFDC_TOKEN_REST` | Outbound Service (SCO3) — HTTP · Path `/` (class ใส่ path เต็มเอง — ใช้ทั้งขอ token และยิง data) | `src/zbc_sfdc_token_rest.sco3.xml` | ทุก RICEFW ที่ยิง SFDC | ✅ `9d3da87` |
| `ZCS_SFDC_TOKEN` | Communication Scenario outbound · **Basic** (user = client id · pw = secret ใน `SFDC_DEV`) | `src/zcs_sfdc_token.sco1.xml` | | ✅ `9d3da87` · Basic · published |
| Communication Arrangement `ZCA_SFDC_TOKEN` | Fiori config × `SFDC_DEV` — ไม่ขึ้น git | — | | ✅ Check Connection ✓ 2026-09-21 |
| `ZCL_UTILITY` | Class — `get_sfdc_token( )` · **`create_sfdc_client( )`** (token + Bearer + client ผ่าน `ZCA_SFDC_TOKEN` — RICEFW แค่ใส่ path/body แล้ว execute) · `parse_sfdc_token_response( )` (pure) | `src/zcl_utility.clas.abap` | ZARE002 · ZARI002 | ✅ `9d3da87` · token จริง 200 · ZARE002 Reject ผ่านถึง SFDC แล้ว (2026-09-21) |
| `ZCL_UTILITY` testclasses | parse token / error response — ไม่ต่อ SFDC | `src/zcl_utility.clas.testclasses.abap` | | ✅ `9d3da87` · 4 test เขียว |

## ผู้เรียกที่ต้องปรับ

| RICEFW | class | สถานะ |
|---|---|---|
| ZARE002 | `ZCL_ZARE002_SFDC_RESULT` — `send` / `check_connection` ขอ client จาก `create_sfdc_client` | ✅ `fplus-zare002` `11b4185` (2026-09-21) |
| ZARI002 | `ZCL_ZARI002_SFDC_NOTIFY` — เหมือนกัน (ping `/services/data/` ของมันก็ไม่พิสูจน์ token) | ⬜ นอก scope ZARE002 |
