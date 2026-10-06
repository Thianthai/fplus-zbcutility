"! ทดสอบเฉพาะ parse — ไม่ต่อ Salesforce
CLASS ltc_utility DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    "! token response ปกติ (key ตามที่ Salesforce ส่งจริง ไม่มี expires_in)
    METHODS sfdc_token_200_is_success     FOR TESTING.
    "! 400 invalid_client -> error_code + description
    METHODS sfdc_token_400_is_failure     FOR TESTING.
    "! 200 แต่ไม่มี access_token -> NO_TOKEN
    METHODS sfdc_token_200_without_token  FOR TESTING.
    "! HTML แทน JSON -> NO_TOKEN + เศษ body ไม่ dump
    METHODS sfdc_token_garbage            FOR TESTING.

ENDCLASS.


CLASS ltc_utility IMPLEMENTATION.

  METHOD sfdc_token_200_is_success.
    DATA(lv_json) = `{"access_token":"00DAz000001TEST!AQEAQ_dummy_token","signature":"sig=","scope":"api",`
                 && `"instance_url":"https://one-two-trading--dev.sandbox.my.salesforce.com",`
                 && `"id":"https://test.salesforce.com/id/00DAz000001/005Az000001","token_type":"Bearer","issued_at":"1758440000000"}`.

    DATA(ls_result) = zcl_utility=>parse_sfdc_token_response( iv_json = lv_json iv_http_status = 200 ).

    cl_abap_unit_assert=>assert_true( ls_result-success ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-access_token exp = '00DAz000001TEST!AQEAQ_dummy_token' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-instance_url exp = 'https://one-two-trading--dev.sandbox.my.salesforce.com' ).
    cl_abap_unit_assert=>assert_initial( ls_result-error_code ).
  ENDMETHOD.

  METHOD sfdc_token_400_is_failure.
    DATA(lv_json) = `{"error":"invalid_client","error_description":"invalid client credentials"}`.

    DATA(ls_result) = zcl_utility=>parse_sfdc_token_response( iv_json = lv_json iv_http_status = 400 ).

    cl_abap_unit_assert=>assert_false( ls_result-success ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-http_status   exp = 400 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-error_code    exp = 'invalid_client' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-error_message exp = 'invalid client credentials' ).
    cl_abap_unit_assert=>assert_initial( ls_result-access_token ).
  ENDMETHOD.

  METHOD sfdc_token_200_without_token.
    DATA(ls_result) = zcl_utility=>parse_sfdc_token_response( iv_json = `{"token_type":"Bearer"}` iv_http_status = 200 ).

    cl_abap_unit_assert=>assert_false( ls_result-success ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-error_code exp = zcl_utility=>gc_sfdc_err_no_token ).
  ENDMETHOD.

  METHOD sfdc_token_garbage.
    DATA(ls_result) = zcl_utility=>parse_sfdc_token_response( iv_json = `<html>Bad Gateway</html>` iv_http_status = 502 ).

    cl_abap_unit_assert=>assert_false( ls_result-success ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-error_code exp = zcl_utility=>gc_sfdc_err_no_token ).
    cl_abap_unit_assert=>assert_true( xsdbool( ls_result-error_message CS 'Bad Gateway' ) ).
  ENDMETHOD.

ENDCLASS.




"! ทดสอบ get_form_graphic และ get_form_graphic_base64 ด้วย SQL test double
"! ไม่แตะข้อมูลจริงใน ZTBC_GRAPHIC
CLASS ltc_form_graphic DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CLASS-DATA:
      "! SQL test double ของ ZTBC_GRAPHIC
      go_environment TYPE REF TO if_osql_test_environment.

    DATA:
      "! รูปจำลองที่ active (4 byte แรกของไฟล์ PNG)
      gv_active_content   TYPE xstring,
      "! รูปจำลองที่ไม่ active (4 byte แรกของไฟล์ JPEG)
      gv_inactive_content TYPE xstring.

    "! สร้าง test double ของ ZTBC_GRAPHIC ครั้งเดียวต่อ class
    CLASS-METHODS class_setup.

    "! ทำลาย test double
    CLASS-METHODS class_teardown.

    "! ล้าง test double แล้วใส่รูปจำลอง 2 รูป (active 1 ไม่ active 1)
    METHODS setup.

    "! ชื่อที่ active -> ได้รูป
    METHODS active_name_returns_content   FOR TESTING.
    "! ส่งชื่อเป็นตัวพิมพ์เล็ก -> ยังหาเจอ
    METHODS lower_case_name_is_found      FOR TESTING.
    "! ชื่อที่ไม่ active -> ค่าว่าง
    METHODS inactive_name_returns_initial FOR TESTING.
    "! ชื่อที่ไม่มีใน table -> ค่าว่าง
    METHODS unknown_name_returns_initial  FOR TESTING.
    "! base64 ของรูปที่ active ตรงกับค่าที่คำนวณไว้
    METHODS base64_of_active_content      FOR TESTING.
    "! base64 ของชื่อที่ไม่มีใน table -> ค่าว่าง
    METHODS base64_of_unknown_is_initial  FOR TESTING.

ENDCLASS.


CLASS ltc_form_graphic IMPLEMENTATION.

  METHOD class_setup.
    go_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZTBC_GRAPHIC' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    go_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    go_environment->clear_doubles( ).

    gv_active_content   = '89504E47'.
    gv_inactive_content = 'FFD8FFE0'.

    DATA lt_graphics TYPE STANDARD TABLE OF ztbc_graphic WITH EMPTY KEY.

    lt_graphics = VALUE #( ( uuid            = '00000000000000000000000000000001'
                             graphic_name    = 'TEST_ACTIVE'
                             is_active       = abap_true
                             graphic_content = gv_active_content )
                           ( uuid            = '00000000000000000000000000000002'
                             graphic_name    = 'TEST_INACTIVE'
                             is_active       = abap_false
                             graphic_content = gv_inactive_content ) ).

    go_environment->insert_test_data( lt_graphics ).
  ENDMETHOD.

  METHOD active_name_returns_content.
    cl_abap_unit_assert=>assert_equals( act = zcl_utility=>get_form_graphic( 'TEST_ACTIVE' )
                                        exp = gv_active_content ).
  ENDMETHOD.

  METHOD lower_case_name_is_found.
    cl_abap_unit_assert=>assert_equals( act = zcl_utility=>get_form_graphic( 'test_active' )
                                        exp = gv_active_content ).
  ENDMETHOD.

  METHOD inactive_name_returns_initial.
    cl_abap_unit_assert=>assert_initial( zcl_utility=>get_form_graphic( 'TEST_INACTIVE' ) ).
  ENDMETHOD.

  METHOD unknown_name_returns_initial.
    cl_abap_unit_assert=>assert_initial( zcl_utility=>get_form_graphic( 'TEST_UNKNOWN' ) ).
  ENDMETHOD.

  METHOD base64_of_active_content.
    " 89504E47 แปลงเป็น base64 ได้ iVBORw==
    cl_abap_unit_assert=>assert_equals( act = zcl_utility=>get_form_graphic_base64( 'TEST_ACTIVE' )
                                        exp = `iVBORw==` ).
  ENDMETHOD.

  METHOD base64_of_unknown_is_initial.
    cl_abap_unit_assert=>assert_initial( zcl_utility=>get_form_graphic_base64( 'TEST_UNKNOWN' ) ).
  ENDMETHOD.

ENDCLASS.


"! ทดสอบ get_local_datetime ด้วย SQL test double ของ ZTBC_PARAM
"! ส่งเวลาที่รู้ค่าแน่นอนเข้าไป ไม่พึ่งนาฬิกาจริง ยกเว้นเคสที่ไม่ส่งเวลา
"! ไม่ขึ้นกับ param ที่ maintain จริงบน tenant
CLASS ltc_local_datetime DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CLASS-DATA:
      "! SQL test double ของ ZTBC_PARAM
      go_environment TYPE REF TO if_osql_test_environment.

    "! สร้าง test double ของ ZTBC_PARAM ครั้งเดียวต่อ class
    CLASS-METHODS class_setup.

    "! ทำลาย test double
    CLASS-METHODS class_teardown.

    "! ล้าง test double ทุก test -> ค่าเริ่มต้นคือไม่มี param
    METHODS setup.

    "! ไม่มี param, TIMESTAMPL 07:22:57 UTC -> 14:22:57 วันเดียวกัน
    METHODS converts_timestampl        FOR TESTING.
    "! ไม่มี param, TIMESTAMP 07:22:57 UTC -> 14:22:57 วันเดียวกัน
    METHODS converts_timestamp         FOR TESTING.
    "! ไม่มี param, 17:30:00 UTC -> 00:30:00 ของวันถัดไป
    METHODS crosses_midnight           FOR TESTING.
    "! ไม่มี param, ไม่ส่งเวลา -> ใช้เวลาปัจจุบันและแปลงสำเร็จ
    METHODS no_input_uses_now          FOR TESTING.
    "! param = UTC+8, 07:22:57 UTC -> 15:22:57 พิสูจน์ว่าอ่าน param จริง
    METHODS param_timezone_is_used     FOR TESTING.
    "! param = THA ซึ่งไม่มีบน tenant -> fallback เป็น UTC+7 ได้ 14:22:57
    METHODS invalid_param_falls_back   FOR TESTING.

    "! ใส่ param BC / TIMEZONE / LOCAL ลง test double
    "! @parameter iv_timezone | ค่า timezone ที่ต้องการ
    METHODS maintain_timezone
      IMPORTING iv_timezone TYPE ztbc_param-low_value.

ENDCLASS.


CLASS ltc_local_datetime IMPLEMENTATION.

  METHOD class_setup.
    go_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZTBC_PARAM' ) ) ).
  ENDMETHOD.


  METHOD class_teardown.
    go_environment->destroy( ).
  ENDMETHOD.


  METHOD setup.
    go_environment->clear_doubles( ).
  ENDMETHOD.


  METHOD maintain_timezone.

    DATA lt_param TYPE STANDARD TABLE OF ztbc_param WITH EMPTY KEY.

    " ZCL_PARAM กรองเฉพาะ record ที่ start_date <= วันนี้ <= end_date
    lt_param = VALUE #( ( company_code = ''
                          module_id    = 'BC'
                          app_id       = 'UTILITY'
                          param_name   = 'TIMEZONE'
                          param_ext    = 'LOCAL'
                          sequence     = 1
                          start_date   = '19000101'
                          end_date     = '99991231'
                          param_sign   = 'I'
                          param_option = 'EQ'
                          low_value    = iv_timezone ) ).

    go_environment->insert_test_data( lt_param ).

  ENDMETHOD.


  METHOD converts_timestampl.

    DATA lv_timestamp TYPE timestampl.

    " ใช้ CONVERT แทนการเขียนเลขตรง ๆ เพราะ TIMESTAMPL เป็น packed ที่มีทศนิยม
    CONVERT DATE '20260930' TIME '072257'
            INTO TIME STAMP lv_timestamp TIME ZONE 'UTC'.

    zcl_utility=>get_local_datetime( EXPORTING iv_timestamp = lv_timestamp
                                     IMPORTING ev_date      = DATA(lv_date)
                                               ev_time      = DATA(lv_time)
                                               ev_subrc     = DATA(lv_subrc) ).

    cl_abap_unit_assert=>assert_equals( act = lv_subrc exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lv_date  exp = '20260930' ).
    cl_abap_unit_assert=>assert_equals( act = lv_time  exp = '142257' ).

  ENDMETHOD.


  METHOD converts_timestamp.

    DATA lv_timestamp TYPE timestamp.

    CONVERT DATE '20260930' TIME '072257'
            INTO TIME STAMP lv_timestamp TIME ZONE 'UTC'.

    zcl_utility=>get_local_datetime( EXPORTING iv_timestamp = lv_timestamp
                                     IMPORTING ev_date      = DATA(lv_date)
                                               ev_time      = DATA(lv_time)
                                               ev_subrc     = DATA(lv_subrc) ).

    cl_abap_unit_assert=>assert_equals( act = lv_subrc exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lv_date  exp = '20260930' ).
    cl_abap_unit_assert=>assert_equals( act = lv_time  exp = '142257' ).

  ENDMETHOD.


  METHOD crosses_midnight.

    DATA lv_timestamp TYPE timestampl.

    CONVERT DATE '20260930' TIME '173000'
            INTO TIME STAMP lv_timestamp TIME ZONE 'UTC'.

    zcl_utility=>get_local_datetime( EXPORTING iv_timestamp = lv_timestamp
                                     IMPORTING ev_date      = DATA(lv_date)
                                               ev_time      = DATA(lv_time)
                                               ev_subrc     = DATA(lv_subrc) ).

    cl_abap_unit_assert=>assert_equals( act = lv_subrc exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lv_date  exp = '20261001' ).
    cl_abap_unit_assert=>assert_equals( act = lv_time  exp = '003000' ).

  ENDMETHOD.


  METHOD no_input_uses_now.

    zcl_utility=>get_local_datetime( IMPORTING ev_date  = DATA(lv_date)
                                               ev_subrc = DATA(lv_subrc) ).

    " subrc 8 แปลว่า timezone UTC+7 ไม่มีบน tenant นี้
    cl_abap_unit_assert=>assert_equals( act = lv_subrc exp = 0 ).
    cl_abap_unit_assert=>assert_not_initial( lv_date ).

  ENDMETHOD.


  METHOD param_timezone_is_used.

    DATA lv_timestamp TYPE timestampl.

    maintain_timezone( 'UTC+8' ).

    CONVERT DATE '20260930' TIME '072257'
            INTO TIME STAMP lv_timestamp TIME ZONE 'UTC'.

    zcl_utility=>get_local_datetime( EXPORTING iv_timestamp = lv_timestamp
                                     IMPORTING ev_date      = DATA(lv_date)
                                               ev_time      = DATA(lv_time)
                                               ev_subrc     = DATA(lv_subrc) ).

    cl_abap_unit_assert=>assert_equals( act = lv_subrc exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lv_date  exp = '20260930' ).
    cl_abap_unit_assert=>assert_equals( act = lv_time  exp = '152257' ).

  ENDMETHOD.


  METHOD invalid_param_falls_back.

    DATA lv_timestamp TYPE timestampl.

    " THA ไม่มีบน tenant -> CONVERT ได้ sy-subrc 8 -> ต้องลองใหม่ด้วย UTC+7
    maintain_timezone( 'THA' ).

    CONVERT DATE '20260930' TIME '072257'
            INTO TIME STAMP lv_timestamp TIME ZONE 'UTC'.

    zcl_utility=>get_local_datetime( EXPORTING iv_timestamp = lv_timestamp
                                     IMPORTING ev_date      = DATA(lv_date)
                                               ev_time      = DATA(lv_time)
                                               ev_subrc     = DATA(lv_subrc) ).

    cl_abap_unit_assert=>assert_equals( act = lv_subrc exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lv_date  exp = '20260930' ).
    cl_abap_unit_assert=>assert_equals( act = lv_time  exp = '142257' ).

  ENDMETHOD.

ENDCLASS.
