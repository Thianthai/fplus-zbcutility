# ZBCUTILITY — Object List

`⬜` ยังไม่สร้าง · `🟨` ส่ง code แล้วรอสร้าง · `🟦` activate แล้วรอ push · `✅` อยู่ใน repo

| Object | Type | ไฟล์ | ผู้ใช้ | Status |
|---|---|---|---|---|
| `ZBCUTILITY` | Package | `src/package.devc.xml` | — | ✅ baseline `090520a` (`/src/` · FULL) |
| `ZBC_SFDC_TOKEN_REST` | Outbound Service (SCO3) — HTTP · Path `/` (class ใส่ path เต็มเอง — ใช้ทั้งขอ token และยิง data) | `src/zbc_sfdc_token_rest.sco3.xml` | ทุก RICEFW ที่ยิง SFDC | ✅ `9d3da87` |
| `ZCS_SFDC_TOKEN` | Communication Scenario outbound · **Basic** (user = client id · pw = secret ใน `SFDC_DEV`) | `src/zcs_sfdc_token.sco1.xml` | | ✅ `9d3da87` · Basic · published |
| Communication Arrangement `ZCA_SFDC_TOKEN` | Fiori config × `SFDC_DEV` — ไม่ขึ้น git | — | | ✅ Check Connection ✓ 2026-09-21 |
| `ZCL_UTILITY` | Class — `get_sfdc_token( )` · **`create_sfdc_client( )`** (token + Bearer + client ผ่าน `ZCA_SFDC_TOKEN` — RICEFW แค่ใส่ path/body แล้ว execute) · `parse_sfdc_token_response( )` (pure) · `check_sfdc_connection( )` (GET `/services/data/v66.0/limits` — 200 = arrangement + token ใช้ได้ · ห้ามใช้ `/services/data/` เพราะไม่ต้องใช้ token) | `src/zcl_utility.clas.abap` | ZARE002 · ZARI002 | ✅ `d56f201` · token จริง 200 · ZARE002 Reject ผ่านถึง SFDC แล้ว (2026-09-21) |
| `ZCL_UTILITY` testclasses | parse token / error response — ไม่ต่อ SFDC | `src/zcl_utility.clas.testclasses.abap` | | ✅ `9d3da87` · 4 test เขียว |
| `ZCL_UTILITY` — `get_form_graphic( )` | Method ใหม่ — รับ `graphic_name` (แปลงเป็นตัวพิมพ์ใหญ่) -> คืน `graphic_content` (xstring) ของรูปใน `ZTBC_GRAPHIC` ที่ `is_active = X` · ไม่เจอ = ค่าว่าง | `src/zcl_utility.clas.abap` | Adobe Form ทุก RICEFW | ✅ `09c6848` |
| `ZCL_UTILITY` — `get_form_graphic_base64( )` | Method ใหม่ — เหมือนตัวบนแต่คืน base64 string สำหรับ XML data ของ Adobe Form · ตัวอย่างการเรียก: `fplus-zbcgraphic/docs/04_usage.md` | `src/zcl_utility.clas.abap` | | ✅ `09c6848` |
| `ZCL_UTILITY` testclasses — `ltc_form_graphic` | SQL test double ของ `ZTBC_GRAPHIC` — active / ไม่ active / ไม่มีชื่อ / ตัวพิมพ์เล็ก / base64 | `src/zcl_utility.clas.testclasses.abap` | | ✅ `09c6848` · 6 test เขียว (รวมทั้ง class 10 ตัว) 2026-10-02 |
| `ZCL_UTILITY` — `get_local_datetime( )` | Method ใหม่ — แปลง timestamp UTC (`TIMESTAMP` หรือ `TIMESTAMPL` · ไม่ส่ง = `GET TIME STAMP`) เป็นวันที่ (`ev_date` YYYYMMDD) และเวลา (`ev_time` HHMMSS) ท้องถิ่น · timezone อ่านจาก param `BC / UTILITY / TIMEZONE / LOCAL` ผ่าน `ZCL_PARAM` (`c9832e1` · app ID `PARAM` -> `UTILITY` `0032963`) · ไม่มี param หรือ timezone ใช้ไม่ได้ (subrc 8) -> fallback `UTC+7` · `ev_subrc` ของ CONVERT (0 สำเร็จ · 8 ไม่มี timezone · 12 timestamp ผิด -> date/time ว่าง) · ใช้ EXPORTING ไม่คืน structure โดยตั้งใจ | `src/zcl_utility.clas.abap` | ทุก RICEFW ที่แสดงวันที่/เวลาให้คนไทยอ่าน (เช่น ZSDE002 `ProcessingDate`/`ProcessingTime` — ยังไม่ได้ย้ายมาใช้) | ✅ `7cf83d5` · param `c9832e1` · app ID `UTILITY` `0032963` |
| `ZCL_UTILITY` testclasses — `ltc_local_datetime` | SQL test double ของ `ZTBC_PARAM` · ไม่มี param: TIMESTAMPL และ TIMESTAMP 07:22:57 UTC -> 14:22:57 · 17:30 UTC -> 00:30 วันถัดไป · ไม่ส่งเวลา -> subrc 0 · param `UTC+8` -> 15:22:57 · param `THA` -> fallback 14:22:57 | `src/zcl_utility.clas.testclasses.abap` | | ✅ `c9832e1` · 6 test เขียว 2026-10-05 · `0032963` เขียวทั้ง class 2026-10-06 |

## ผู้เรียกที่ต้องปรับ

| RICEFW | class | สถานะ |
|---|---|---|
| ZARE002 | `ZCL_ZARE002_SFDC_RESULT` — `send` / `check_connection` ขอ client จาก `create_sfdc_client` | ✅ `fplus-zare002` `11b4185` (2026-09-21) |
| ZARI002 | `ZCL_ZARI002_SFDC_NOTIFY` — เหมือนกัน (ping `/services/data/` ของมันก็ไม่พิสูจน์ token) | ⬜ นอก scope ZARE002 |
| ARI001 | arrangement `ZCA_BILLING_LIST_TO_SF` (scenario `ZCS_BILLING_LIST_TO_SF`) เห็นบน `SFDC_DEV` 2026-09-21 — ถ้าเป็น OAuth 2.0 จะเจอ token ค้างแบบเดียวกัน | ⬜ นอก scope · ยังไม่ได้ดู code |

## User for Outbound Communication บน `SFDC_DEV`

| แถว | ใครใช้ | ลบได้เมื่อ |
|---|---|---|
| User ID and Password (client id / secret) | `ZCA_SFDC_TOKEN` | — ตัวหลักของ `ZCL_UTILITY` |
| OAuth 2.0 (Form Field) | arrangement OAuth ที่ยังเหลือ: `ZCA_PAYMENT_RESULT` (ARI002) · `ZCA_BILLING_LIST_TO_SF` (ARI001) — `ZCA_REJECT_RESULT` ของ ZARE002 ลบแล้ว 2026-09-21 | **หลัง** ผู้เรียกทุกตัวย้ายมา `create_sfdc_client` แล้วลบ/เปลี่ยน arrangement ของตัวเอง — platform ไม่ยอมลบ user ที่ยังมี arrangement ชี้อยู่ |

## Config ที่ต้อง maintain (ทุก tenant)

| ใช้กับ | Company | Module | App ID | Parameter Name | Additional Parameter | Seq | Sign | Option | Low Value |
|---|---|---|---|---|---|---|---|---|---|
| `get_local_datetime( )` | (ว่าง) | `BC` | `UTILITY` | `TIMEZONE` | `LOCAL` | 1 | I | EQ | `UTC+7` |

ไม่ maintain = fallback `UTC+7` ในโค้ด (ทำงานได้ แต่เปลี่ยน timezone ไม่ได้โดยไม่ transport)
