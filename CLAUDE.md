# ZBCUTILITY — Utility กลาง

ใช้กฎกลางใน `~/.claude/CLAUDE.md` ทุกข้อ · prefix `Z*` (case by case ตามที่ตกลงกับ RICEFW ทั้งชุด fplus)

## กติกาเฉพาะ package นี้

- **ไม่มี business logic ของ RICEFW ใด** — ของที่อยู่ที่นี่ต้องมีผู้ใช้ ≥ 2 RICEFW หรือเป็นเรื่อง platform
  (auth, connectivity, format) · ถ้าใช้คนเดียวให้อยู่ใน package ของ RICEFW นั้น
- **class กลางมีตัวเดียว `ZCL_UTILITY`** (ผู้ใช้ตั้ง 2026-09-21) — ไม่มี prefix `<APP>` โดยตั้งใจ
  · method ใหม่เพิ่มในนี้ ไม่แตก class · method ตั้งชื่อบอกระบบปลายทาง (`get_sfdc_token` ไม่ใช่ `get_token`)
- **ทุก method เป็น `CLASS-METHODS`** (stateless) · ไม่โยน exception — คืน structure ผลลัพธ์ให้ผู้เรียกตัดสิน
- **ห้ามเก็บ secret ใน code / table** — ทุก credential อยู่ใน Communication System ผ่าน arrangement
  (ตกลง 2026-09-21: ถ้าทางนี้ทำไม่ได้จริงค่อยใช้ `ZTBC_PARAM` พร้อมมาตรการปิดสิทธิ์อ่าน)
- แก้ของในนี้ = กระทบทุก RICEFW ที่เรียก · ห้ามเปลี่ยน signature ของ method ที่มีผู้ใช้แล้ว ให้เพิ่ม method ใหม่
- ABAP Doc ทุก class / method / constant group / type · ห้าม emoji ใน comment ABAP

## Git

| สิ่งที่ทำ | ใคร |
|---|---|
| ABAP object | ผู้ใช้ push ผ่าน abapGit จาก ADT |
| เอกสาร | Claude commit + push เอง |

- `.abapgit.xml` / `package.devc.xml` tenant serialize เอง — commit แรกต้องเป็นเอกสารล้วนก่อน link
- Remote: https://github.com/Thianthai/fplus-zbcutility.git
