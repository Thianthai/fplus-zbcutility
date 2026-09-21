# ZBCUTILITY — Utility กลางข้าม RICEFW

| Item | Value |
|------|-------|
| Package | **`ZBCUTILITY`** — package เดียว |
| Platform | SAP S/4HANA Cloud **Public Edition** · ABAP for Cloud Development |
| หน้าที่ | ของที่ RICEFW มากกว่า 1 ตัวใช้ร่วมกัน — ไม่มี business logic ของ RICEFW ใดอยู่ที่นี่ |
| ผู้ใช้ปัจจุบัน | **ZARE002** (Reject → Salesforce) · **ZARI002** (แจ้งผลรับข้อมูล → Salesforce) ตามมา |
| Repo sync | abapGit (local ⇄ GitHub ⇄ tenant) |

## สิ่งที่อยู่ในนี้

| Object | Type | หน้าที่ |
|---|---|---|
| `ZCL_UTILITY` | Class | method กลาง — ตอนนี้: `get_sfdc_token( )` ขอ OAuth token จาก Salesforce ใหม่ทุกครั้ง |
| `ZBC_SFDC_TOKEN_REST` | Outbound Service | → `/services/oauth2/token` ของ Salesforce |
| `ZCS_SFDC_TOKEN` | Communication Scenario (outbound · Basic auth) | ให้ platform ใส่ client id/secret เอง — secret ไม่อยู่ใน code |

Communication Arrangement `ZCA_SFDC_TOKEN` × Communication System `SFDC_DEV` เป็น config ใน Fiori ไม่ขึ้น git

## ทำไมต้องมี — เรื่อง token ของ Salesforce

Salesforce client credentials flow **ไม่ส่ง `expires_in`** → Communication Arrangement แบบ OAuth 2.0 ของ SAP
ถือ token ค้างและไม่ refresh แม้เจอ 401 (พิสูจน์ 2026-09-21 ที่ ZARE002 · SAP Community ยืนยันเป็นพฤติกรรม
Public Cloud) → ทุก RICEFW ที่ยิง Salesforce ต้องขอ token ใหม่เองผ่าน `zcl_utility=>get_sfdc_token( )`
แล้วใส่ `Authorization: Bearer` ในการเรียกของตัวเอง · รายละเอียดอยู่ใน `fplus-zare002/docs/06_open_questions.md` OQ-34

## Repository layout

```
fplus-zbcutility/
├── README.md
├── CLAUDE.md
├── docs/01_objects.md            # object list + status
├── .abapgit.xml                  # tenant serialize เอง ห้ามแก้มือ (ยังไม่มี)
└── src/                          # abapGit sync (ยังไม่มี)
```

## Sync workflow

เหมือน RICEFW อื่น: ABAP object ผู้ใช้สร้างใน ADT แล้ว push ผ่าน abapGit · เอกสาร Claude commit + push
