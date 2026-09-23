# ส่งให้ session ZARI002 — เปลี่ยนมาใช้ ZCL_UTILITY / ZCA_SFDC_TOKEN

> เขียนโดย session ZARE002 · 2026-09-23
> อ้างอิง: repo `fplus-zbcutility` (`docs/01_objects.md`) และ `fplus-zare002` (`docs/09`, `CLAUDE.md`)

## 1. ปัญหาที่ต้องแก้

`ZCL_ZARI002_SFDC_NOTIFY` ยิง Salesforce ผ่าน Communication Arrangement **`ZCA_PAYMENT_RESULT`**
ที่ตั้ง authentication เป็น **OAuth 2.0** แล้วให้ platform จัดการ token ให้

**Salesforce client credentials grant ไม่ส่ง `expires_in` กลับมา** ทำให้ SAP ถือ token ค้างไว้
ไม่ขอใหม่แม้เจอ 401 (พิสูจน์แล้วที่ ZARE002 2026-09-21 และ SAP Community ยืนยันเป็นพฤติกรรม
ของ Public Cloud) อาการคือ **วันแรกยิงผ่าน วันถัดมาได้ 401 `INVALID_SESSION_ID` ทั้งที่ไม่ได้แก้อะไร**
workaround ชั่วคราวคือกด Check Connection ที่ arrangement ซึ่งบังคับให้ขอ token ใหม่

ZARE002 เจออาการนี้เต็ม ๆ ตอนทดสอบ Reject แล้วแก้ถาวรด้วยวิธีข้างล่าง
ARI002 ยังไม่เจอเพราะยิงไม่บ่อย แต่จะเจอแน่ถ้าเว้นช่วง

## 2. ทางแก้ที่ใช้อยู่จริง

ขอ token เองทุกครั้งที่ยิง ผ่าน arrangement ที่เป็น **Basic auth** แล้วใส่ `Authorization: Bearer` เอง
ของกลางทั้งหมดอยู่ที่ package **`ZBCUTILITY`** repo <https://github.com/Thianthai/fplus-zbcutility>

| Object | ชนิด | หน้าที่ |
|---|---|---|
| `ZCL_UTILITY` | Class (static ทั้งหมด) | `get_sfdc_token( )` · `create_sfdc_client( )` · `check_sfdc_connection( )` · `parse_sfdc_token_response( )` |
| `ZBC_SFDC_TOKEN_REST` | Outbound Service (SCO3) | Path ตั้งเป็น `/` เท่านั้น ให้ class ใส่ path เต็มเอง |
| `ZCS_SFDC_TOKEN` | Communication Scenario outbound | authentication แบบ **Basic** |
| `ZCA_SFDC_TOKEN` | Communication Arrangement × `SFDC_DEV` | user = client id · password = client secret |

`create_sfdc_client( )` ทำ 2 อย่างในตัวเดียว
1. ขอ token ใหม่ (POST `grant_type=client_credentials` ไป `/services/oauth2/token`)
2. สร้าง HTTP client ผ่าน `ZCA_SFDC_TOKEN` แล้วใส่ header `Authorization: Bearer <token>` ให้เลย

header `Basic` ที่ platform แนบมาถูก header ของเราเขียนทับ Salesforce จึงเห็นแค่ Bearer
**arrangement ตัวเดียวใช้ได้ทั้งขอ token และยิง data** (พิสูจน์แล้ว ไม่ต้องมี arrangement แยก)

ราคาที่จ่าย: 1 request เพิ่มต่อการยิง 1 ครั้ง (ประมาณ 200 ms) แลกกับ token ที่ไม่มีวันค้าง

## 3. สิ่งที่ ZARI002 ต้องแก้

### 3.1 `ZCL_ZARI002_SFDC_NOTIFY` — เปลี่ยน `create_client`

ของเดิม
```abap
  METHOD create_client.
    DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                             comm_scenario = gc_comm_scenario
                             service_id    = gc_service_id ).
    ro_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
  ENDMETHOD.
```

ของใหม่ (ตัวอย่างจาก `ZCL_ZARE002_SFDC_RESULT` ที่ใช้งานจริงอยู่)
```abap
  METHOD create_client.
    zcl_utility=>create_sfdc_client( IMPORTING eo_client = ro_client
                                               es_error  = DATA(ls_error) ).
    " ro_client ว่าง = ขอ token ไม่ได้ ผู้เรียกต้องเช็ค IS BOUND ก่อนใช้
    " ls_error-http_status กับ error_code เอาไปใส่ log ได้
  ENDMETHOD.
```

จุดที่ต้องปรับตาม
- `create_sfdc_client` เป็น `EXPORTING` ไม่ใช่ returning และ **อาจคืน client ว่าง** ต้องเช็ค `IS BOUND`
  ก่อนใช้ทุกครั้ง (เคสขอ token ไม่ได้) แล้วบันทึก log ว่าไม่ได้ส่ง
- signature มี `RAISING cx_http_dest_provider_error cx_web_http_client_error` ต้องอยู่ใน `TRY` เหมือนเดิม
- ลบ constant `gc_comm_scenario` และ `gc_service_id` ทิ้ง ไม่ต้องรู้ชื่อ arrangement อีกต่อไป

### 3.2 `check_connection` ใช้ ping ที่ไม่พิสูจน์อะไรเลย

ของเดิม ping ไปที่ `gc_path_ping = '/services/data/'` ซึ่ง **เป็น endpoint ที่ไม่ต้องใช้ token**
ได้ 200 เสมอแม้ token จะหมดอายุ จึงบอกไม่ได้ว่าใช้ได้จริง

เปลี่ยนเป็นเรียก `zcl_utility=>check_sfdc_connection( )` ซึ่งยิง `/services/data/v66.0/limits`
(endpoint ที่ต้องใช้ token จริง) แล้วคืน HTTP status
- 200 = arrangement และ token ใช้ได้จริง
- 401 = Salesforce ไม่รับ token
- 0 = ต่อไม่ถึงหรือขอ token ไม่ได้

### 3.3 ของเดิมที่เลิกใช้

`ZCA_PAYMENT_RESULT` / `ZCS_PAYMENT_RESULT` / `ZARI002_PAYMENT_RESULT_REST` จะไม่มีใครเรียกอีก
ลบได้เมื่อทดสอบผ่าน โดย **ลบตามลำดับ** arrangement (Fiori) -> scenario -> outbound service (ADT)
ไม่งั้นติด dependency

ZARE002 ทำแบบเดียวกันไปแล้วกับชุด `ZCA_REJECT_RESULT` (ดู `fplus-zare002` commit `651ec78`)

### 3.4 Communication System `SFDC_DEV` — ยังห้ามลบ user OAuth

แถว **User ID and Password** คือของ `ZCA_SFDC_TOKEN` ที่ใช้อยู่
แถว **OAuth 2.0 (Form Field)** ยังมี arrangement อื่นชี้อยู่ (`ZCA_PAYMENT_RESULT` ของ ARI002
และ `ZCA_BILLING_LIST_TO_SF` ของ ARI001) ลบได้ก็ต่อเมื่อย้ายครบทุกตัวแล้ว
ทะเบียนอยู่ที่ `fplus-zbcutility/docs/01_objects.md`

## 4. ทดสอบหลังแก้

1. `check_connection` ต้องได้ 200
2. ยิง notify จริง 1 ครั้ง ดูว่าได้ HTTP 201 เหมือนเดิม
3. **เว้นไว้ 1 วันแล้วยิงซ้ำโดยไม่แตะอะไร** ต้องยังได้ผลเหมือนเดิม (นี่คือเคสที่ของเดิมพัง)

## 5. ข้อควรรู้ที่ ZARE002 เจอมาก่อน

- Path ใน Communication Arrangement เป็น **prefix** `set_uri_path( )` ต่อท้ายไม่ได้แทนที่
  ถ้าตั้ง prefix เป็น path จริงแล้ว class ใส่ path อีกจะได้ 404 -> ตั้ง prefix เป็น `/` เสมอ
- ห้าม print หรือ log ตัว access token
- client secret อยู่ใน Communication System เท่านั้น ABAP มองไม่เห็น ไม่ต้องมี table เก็บ
