# ZBCUTILITY — Utility กลาง

ใช้กฎกลางใน `~/.claude/CLAUDE.md` ทุกข้อ · prefix `Z*` (case by case ตามที่ตกลงกับ RICEFW ทั้งชุด fplus)

## กติกาเฉพาะ package นี้

- **ไม่มี business logic ของ RICEFW ใด** — ของที่อยู่ที่นี่ต้องมีผู้ใช้ ≥ 2 RICEFW หรือเป็นเรื่อง platform
  (auth, connectivity, format) · ถ้าใช้คนเดียวให้อยู่ใน package ของ RICEFW นั้น
- **class กลางมีตัวเดียว `ZCL_UTILITY`** (ผู้ใช้ตั้ง 2026-09-21) — ไม่มี prefix `<APP>` โดยตั้งใจ
  · method ใหม่เพิ่มในนี้ ไม่แตก class · method ตั้งชื่อบอกระบบปลายทาง (`get_sfdc_token` ไม่ใช่ `get_token`)
- **ทุก method เป็น `CLASS-METHODS`** (stateless) · ไม่โยน exception — คืน structure ผลลัพธ์ให้ผู้เรียกตัดสิน
  · **ข้อยกเว้นที่ตั้งใจ:** `get_local_datetime( )` ใช้ EXPORTING (`ev_date` · `ev_time` · `ev_subrc`) แทน structure เพราะผู้ใช้ต้องการแค่ค่าเหล่านี้ (ผู้ใช้สั่ง 2026-10-05)
- **ห้ามเก็บ secret ใน code / table** — ทุก credential อยู่ใน Communication System ผ่าน arrangement
  (ตกลง 2026-09-21: ถ้าทางนี้ทำไม่ได้จริงค่อยใช้ `ZTBC_PARAM` พร้อมมาตรการปิดสิทธิ์อ่าน)
- แก้ของในนี้ = กระทบทุก RICEFW ที่เรียก · ห้ามเปลี่ยน signature ของ method ที่มีผู้ใช้แล้ว ให้เพิ่ม method ใหม่
- ABAP Doc ทุก class / method / constant group / type · ห้าม emoji ใน comment ABAP

## Timezone

- `get_local_datetime( )` อ่าน timezone จาก param `BC / UTILITY / TIMEZONE / LOCAL` ก่อน · ไม่มี หรือ CONVERT ได้ 8 -> fallback `UTC+7` (`gc_local_time_zone`)
- ID ที่พิสูจน์แล้วว่ามีบน tenant: `UTC+7` · `UTC+8` · ส่วน `THA` / `BANGKOK` / `INDCH` ไม่มี -> CONVERT ล้มเงียบ sy-subrc 8
- `cl_abap_context_info=>get_user_time_zone( )` ใช้ไม่ได้ — คืน UTC แม้ user ตั้ง Asia, Bangkok ใน Fiori Settings (เป็นค่าฝั่ง frontend)
- timestamp ที่เก็บลง table ให้เก็บเป็น UTC เสมอ (Fiori แปลงตาม timezone ของคนดูเอง) · แปลงเป็นเวลาไทยเฉพาะตอนส่งออกให้คนอ่าน

## Dependency ข้าม package

| ของใน `ZBCUTILITY` | ใช้ของจาก | ผล |
|---|---|---|
| `get_form_graphic( )` / `get_form_graphic_base64( )` | `ZBCGRAPHIC` (`ZTBC_GRAPHIC` · `ZE_GRAPHIC_NAME` · `ZE_GRAPHIC_CONTENT`) — repo `fplus-zbcgraphic` | **transport `ZBCGRAPHIC` ก่อนหรือพร้อม `ZBCUTILITY` เสมอ** (ผู้ใช้รับเงื่อนไข 2026-10-02) |
| `get_local_datetime( )` | `ZBCPARAM` (`ZCL_PARAM` · `ZCX_PARAM` · `ZTBC_PARAM`) — repo `fplus-zbcparam` | **พึ่งกันสองทาง — ต้อง transport พร้อมกันเท่านั้น** ดูหัวข้อถัดไป (2026-10-06) |

### `ZBCPARAM` <-> `ZBCUTILITY` พึ่งกันสองทาง (ตั้งแต่ 2026-10-06)

| ทิศทาง | ผู้เรียก | ถูกเรียก |
|---|---|---|
| `ZBCUTILITY` -> `ZBCPARAM` | `zcl_utility=>get_local_datetime( )` | `zcl_param=>create_instance( )` / `get_value( )` อ่าน timezone |
| `ZBCPARAM` -> `ZBCUTILITY` | constructor ของ `ZCL_PARAM` | `zcl_utility=>remove_invisible_char( )` ล้าง key field ของ buffer (ย้ายมาจาก `sanitize` · `fplus-zbcparam` `8cb234f`) |

- **Transport:** ทั้ง 2 package อยู่ software component `ZCUSTOM_DEVELOPMENT` เดียวกัน · import ทำทีละ software component
  → **release TR ของทั้ง 2 package ให้ครบก่อน แล้วค่อย import** · ถ้า import ไปทั้งที่ release แค่ TR เดียว ฝั่งที่ขาดจะ activate ไม่ผ่าน
- **Release:** ทั้ง 2 package ติ๊ก Package encapsulated · `ZCL_PARAM` release C1 อยู่ · `ZCL_UTILITY` ไม่ได้ release
  แต่เรียกจาก `ZCL_PARAM` แล้วไม่มี warning (ผู้ใช้ยืนยัน 2026-10-06) จึงยังไม่ต้อง release
- **กันวนไม่รู้จบ:** method ของ `ZCL_UTILITY` ที่ `ZCL_PARAM` เรียก **ห้ามเรียก `ZCL_PARAM` กลับ** เด็ดขาด
  เพราะ `ZCL_PARAM` เรียกจาก constructor → ทุก `create_instance( )` จะวนซ้ำจน dump
  · ด้วยเหตุนี้ `ZCL_PARAM` จึง**ห้ามใช้ `get_local_datetime( )`** (ตัวนั้นเรียก `ZCL_PARAM` อ่าน timezone) — ตกลงไม่ทำเรื่อง timezone ใน `ZCL_PARAM` แล้ว 2026-10-06

## Git

| สิ่งที่ทำ | ใคร |
|---|---|
| ABAP object | ผู้ใช้ push ผ่าน abapGit จาก ADT |
| เอกสาร | Claude commit + push เอง |

- `.abapgit.xml` / `package.devc.xml` tenant serialize เอง — commit แรกต้องเป็นเอกสารล้วนก่อน link
- Remote: https://github.com/Thianthai/fplus-zbcutility.git
