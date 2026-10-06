"! Utility Class กลางของทุก RICEFW
CLASS zcl_utility DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    TYPES:
      "! result การขอ token จาก Salesforce
      BEGIN OF ty_sfdc_token_result,
        access_token  TYPE string,
        instance_url  TYPE string,
        http_status   TYPE i,
        success       TYPE abap_bool,
        error_code    TYPE string,
        error_message TYPE string,
      END OF ty_sfdc_token_result.

    CONSTANTS:
      "! error_code จาก class
      gc_sfdc_err_not_reachable TYPE string VALUE 'NOT_REACHABLE',
      gc_sfdc_err_parse         TYPE string VALUE 'PARSE_ERROR',
      gc_sfdc_err_no_token      TYPE string VALUE 'NO_TOKEN'.

    "! ขอ OAuth token ใหม่จาก Salesforce ทุกครั้งที่เรียก
    "! เหตุผลคือ Salesforce client credentials ไม่ส่ง expires_in ทำให้ Communication Arrangement แบบ OAuth ถือ token ค้าง
    "! ยิงผ่าน Communication Arrangement: ZCA_SFDC_TOKEN แบบ Basic Auth. ซึ่ง platform จะแนบ client id/secret จาก Communication System เอง ABAP จะมองไม่เห็น
    "! คืน access_token ให้ caller เอาไปใส่ header Authorization: Bearer ในการ call API ต่อไป
    CLASS-METHODS get_sfdc_token
      RETURNING VALUE(rs_result) TYPE ty_sfdc_token_result.

    "! ขอ token ใหม่ แล้วสร้าง HTTP client ผ่าน ZCA_SFDC_TOKEN พร้อม Authorization: Bearer ที่ผูกกับ HTTP header ให้แล้ว
    "! caller แค่ set_uri_path / header / body ของตัวเองแล้ว execute (Path ของ Communication Arrangement เป็น "/" ฝั่ง caller ต้องใส่ path เต็มเอง
    "! ขอ token ไม่ได้ = eo_client ว่าง และ es_error มีค่า ซึ่ง caller ต้องเช็ค IS BOUND ก่อนใช้
    "! ปิด client เองหลังใช้ (lo_client->close)
    CLASS-METHODS create_sfdc_client
      EXPORTING eo_client TYPE REF TO if_web_http_client
                es_error  TYPE ty_sfdc_token_result
      RAISING   cx_http_dest_provider_error
                cx_web_http_client_error.

    "! ทดสอบว่า Communication Arrangement + token ใช้ได้จริง — ขอ token แล้ว GET /services/data/v66.0/limits (endpoint ที่ต้องใช้ token)
    "! คืน 200 = ใช้ได้
    "! คืน 401 = Salesforce ไม่รับ token
    "! คืน 0 = ต่อไม่ถึง หรือขอ token ไม่ได้ (http_status ของ token ถ้ามี)
    "! ห้ามใช้ /services/data/ เป็น ping เพราะ endpoint นั้นไม่ต้องใช้ token จะได้ 200 เสมอ
    CLASS-METHODS check_sfdc_connection
      RETURNING VALUE(rv_status) TYPE i.

    "! อ่าน token response ของ Salesforce
    "! ถ้าสำเร็จ คืน access_token + instance_url
    "! ถ้าไม่สำเร็จ คืน error + error_description
    "! แยกออกมาสำหรับให้ทดสอบได้โดยไม่ต่อไปที่ Salesforce
    CLASS-METHODS parse_sfdc_token_response
      IMPORTING iv_json          TYPE string
                iv_http_status   TYPE i
      RETURNING VALUE(rs_result) TYPE ty_sfdc_token_result.

    "! ดึงรูปจากแอป Maintain Form Graphics (package ZBCGRAPHIC) เพื่อ binding ใน Adobe Form
    "! แปลง iv_graphic_name เป็นตัวพิมพ์ใหญ่ก่อน เพราะเก็บชื่อเป็นตัวพิมพ์ใหญ่เสมอ
    "! คืนเป็น xstring
    "! คืนเฉพาะรูปที่ is_active = X
    "! ไม่เจอชื่อ หรือรูปไม่ active = คืนค่าว่าง
    CLASS-METHODS get_form_graphic
      IMPORTING iv_graphic_name           TYPE ze_graphic_name
      RETURNING VALUE(rv_graphic_content) TYPE ze_graphic_content.

    "! เหมือน get_form_graphic แต่คืนเป็น base64 สำหรับใส่ใน XML data ของ Adobe Form
    "! ไม่เจอชื่อ หรือรูปไม่ active = คืนค่าว่าง
    CLASS-METHODS get_form_graphic_base64
      IMPORTING iv_graphic_name          TYPE ze_graphic_name
      RETURNING VALUE(rv_graphic_base64) TYPE string.

    "! แปลงเวลา UTC เป็นวันที่และเวลาตาม local timezone
    "! timezone อ่านจาก constant parameter ผ่าน ZCL_PARAM
    "! ไม่มี param หรือ param เป็น timezone ที่ไม่ถูกต้อง จะใช้ UTC+7 แทน
    "! ไม่ส่ง iv_timestamp = ใช้เวลาปัจจุบันของระบบ
    "! ส่ง iv_timestamp = แปลงเวลาจาก iv_timestamp แทน รับได้ทั้ง TIMESTAMP และ TIMESTAMPL
    "! แปลงไม่สำเร็จ = ev_subrc ไม่เป็น 0 และ ev_date กับ ev_time ว่าง
    "! อ่าน ZTBC_PARAM ทุกครั้งที่เรียก ควรเรียกครั้งเดียว ไม่ควรเรียกใน loop
    "! @parameter iv_timestamp | เวลา UTC ที่ต้องการแปลง
    "! @parameter ev_date      | วันที่ local YYYYMMDD
    "! @parameter ev_time      | เวลา local HHMMSS
    "! @parameter ev_subrc     | sy-subrc ของ CONVERT TIME STAMP รอบที่ใช้จริง
    "!                         | 0 = สำเร็จ
    "!                         | 8 = ไม่มี timezone นี้บน tenant
    "!                         | 12 = timestamp ที่ส่งมาไม่ถูกต้อง
    CLASS-METHODS get_local_datetime
      IMPORTING iv_timestamp TYPE p OPTIONAL
      EXPORTING ev_date      TYPE d
                ev_time      TYPE t
                ev_subrc     TYPE sysubrc.

    "! ลบ invisible character (NBSP, zero-width space, BOM, ideographic space)
    "! ที่อาจติดมาจากการ copy-paste จาก Excel / Word / web
    CLASS-METHODS remove_invisible_char
      IMPORTING iv_text        TYPE clike
      RETURNING VALUE(rv_text) TYPE string.

  PRIVATE SECTION.

    CONSTANTS:
      "! Communication Scenario + Outbound Service กลางสำหรับขอ Token แบบ Basic Auth.
      gc_sfdc_comm_scenario TYPE sxco_cds_object_name VALUE 'ZCS_SFDC_TOKEN',
      gc_sfdc_service_id    TYPE c LENGTH 40          VALUE 'ZBC_SFDC_TOKEN_REST',
      gc_sfdc_path_token    TYPE string               VALUE '/services/oauth2/token',
      gc_sfdc_path_ping     TYPE string               VALUE '/services/data/v66.0/limits',
      gc_http_ok            TYPE i                    VALUE 200,

      "! timezone ประเทศไทย
      "! ใช้ UTC+7 เพราะเป็น ID ที่มีอยู่จริงบน tenant
      "! THA, BANGKOK และ INDCH ไม่มี ทำให้ CONVERT TIME STAMP ไม่ผ่านด้วย sy-subrc 8
      "! cl_abap_context_info=>get_user_time_zone( ) ใช้ไม่ได้ เพราะคืน UTC แม้ user ตั้ง Asia/Bangkok ไว้
      gc_local_time_zone    TYPE timezone             VALUE 'UTC+7'.

ENDCLASS.


CLASS zcl_utility IMPLEMENTATION.

  METHOD get_sfdc_token.

    TRY.
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                 comm_scenario = gc_sfdc_comm_scenario
                                 service_id    = gc_sfdc_service_id ).

        DATA(lo_client) = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).

        DATA(lo_request) = lo_client->get_http_request( ).

        lo_request->set_uri_path( gc_sfdc_path_token ).

        " form field ตั้ง Content-Type: application/x-www-form-urlencoded ให้เอง
        lo_request->set_form_field( i_name  = 'grant_type'
                                    i_value = 'client_credentials' ).

        DATA(lo_response) = lo_client->execute( if_web_http_client=>post ).

        rs_result = parse_sfdc_token_response( iv_json        = lo_response->get_text( )
                                               iv_http_status = lo_response->get_status( )-code ).

        lo_client->close( ).

      CATCH cx_root.
        " ถ้าต่อไม่ถึง Salesforce หรือ Communication Arrangement พัง
        rs_result-http_status = 0.
        rs_result-success     = abap_false.
        rs_result-error_code  = gc_sfdc_err_not_reachable.
    ENDTRY.

  ENDMETHOD.


  METHOD create_sfdc_client.

    CLEAR: eo_client, es_error.

    DATA(ls_token) = get_sfdc_token( ).

    IF ls_token-success = abap_false.
      es_error = ls_token.
      CLEAR es_error-access_token.
      RETURN.
    ENDIF.

    DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                             comm_scenario = gc_sfdc_comm_scenario
                             service_id    = gc_sfdc_service_id ).

    eo_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).

    eo_client->get_http_request( )->set_header_field( i_name  = 'Authorization'
                                                      i_value = |Bearer { ls_token-access_token }| ).

  ENDMETHOD.


  METHOD check_sfdc_connection.

    TRY.
        create_sfdc_client( IMPORTING eo_client = DATA(lo_client)
                                      es_error  = DATA(ls_error) ).

        IF lo_client IS NOT BOUND.
          rv_status = ls_error-http_status.
          RETURN.
        ENDIF.

        lo_client->get_http_request( )->set_uri_path( gc_sfdc_path_ping ).

        DATA(lo_response) = lo_client->execute( if_web_http_client=>get ).

        rv_status = lo_response->get_status( )-code.

        lo_client->close( ).

      CATCH cx_root.
        rv_status = 0.
    ENDTRY.

  ENDMETHOD.


  METHOD parse_sfdc_token_response.

    rs_result-http_status = iv_http_status.

    DATA lv_member TYPE string.

    TRY.
        DATA(lo_reader) = cl_sxml_string_reader=>create( cl_abap_conv_codepage=>create_out( )->convert( iv_json ) ).

        DO.
          DATA(lo_node) = lo_reader->read_next_node( ).

          IF lo_node IS INITIAL.
            EXIT.
          ENDIF.

          CASE lo_node->type.

            WHEN if_sxml_node=>co_nt_element_open.
              CLEAR lv_member.

              LOOP AT CAST if_sxml_open_element( lo_node )->get_attributes( ) INTO DATA(lo_attribute).
                IF lo_attribute->qname-name = 'name'.
                  lv_member = lo_attribute->get_value( ).
                ENDIF.
              ENDLOOP.

            WHEN if_sxml_node=>co_nt_value.
              DATA(lv_value) = CAST if_sxml_value_node( lo_node )->get_value( ).

              CASE lv_member.
                WHEN 'access_token'.      rs_result-access_token  = lv_value.
                WHEN 'instance_url'.      rs_result-instance_url  = lv_value.
                WHEN 'error'.             rs_result-error_code    = lv_value.
                WHEN 'error_description'. rs_result-error_message = lv_value.
              ENDCASE.

              CLEAR lv_member.

          ENDCASE.
        ENDDO.

      CATCH cx_root.
        rs_result-success    = abap_false.
        rs_result-error_code = gc_sfdc_err_parse.
        RETURN.
    ENDTRY.

    IF iv_http_status = gc_http_ok AND rs_result-access_token IS NOT INITIAL.
      rs_result-success = abap_true.
      RETURN.
    ENDIF.

    rs_result-success = abap_false.

    " ถ้าได้ HTTP Status 200 แต่ไม่มี access_token หรือ body format ไม่ถูกต้อง
    IF rs_result-error_code IS INITIAL.
      rs_result-error_code    = gc_sfdc_err_no_token.
      rs_result-error_message = substring( val = iv_json
                                           len = nmin( val1 = strlen( iv_json ) val2 = 100 ) ).
    ENDIF.

  ENDMETHOD.


  METHOD get_form_graphic.

    " แอปเก็บ graphic_name เป็นตัวพิมพ์ใหญ่เสมอ
    DATA lv_graphic_name TYPE ze_graphic_name.

    lv_graphic_name = to_upper( iv_graphic_name ).

    " graphic_name ไม่ซ้ำทั้ง table เพราะแอปมี validation กันไว้
    SELECT SINGLE graphic_content
      FROM ztbc_graphic
      WHERE graphic_name = @lv_graphic_name
        AND is_active    = @abap_true
      INTO @rv_graphic_content.

  ENDMETHOD.


  METHOD get_form_graphic_base64.

    DATA(lv_graphic_content) = get_form_graphic( iv_graphic_name ).

    IF lv_graphic_content IS INITIAL.
      RETURN.
    ENDIF.

    rv_graphic_base64 = cl_web_http_utility=>encode_x_base64( lv_graphic_content ).

  ENDMETHOD.


  METHOD get_local_datetime.

    DATA lv_timestamp TYPE timestampl.
    DATA lv_timezone  TYPE timezone.

    CLEAR: ev_date,
           ev_time,
           ev_subrc.

    " ไม่ส่ง iv_timestamp มา -> ใช้เวลาปัจจุบันของระบบ ซึ่งเป็น UTC เสมอ
    " ส่ง iv_timestamp มา -> ย้ายลง TIMESTAMPL ก่อน เพราะ iv_timestamp เป็น packed แบบ generic
    IF iv_timestamp IS SUPPLIED AND iv_timestamp IS NOT INITIAL.
      lv_timestamp = iv_timestamp.
    ELSE.
      GET TIME STAMP FIELD lv_timestamp.
    ENDIF.

    " อ่าน timezone จาก constant parameter ก่อน
    DATA(lo_param) = zcl_param=>create_instance( iv_company_code = ''
                                                 iv_module_id    = 'BC' ).

    TRY.
        lo_param->get_value( EXPORTING iv_app_id     = 'UTILITY'
                                       iv_param_name = 'TIMEZONE'
                                       iv_param_ext  = 'LOCAL'
                             IMPORTING ev_value      = lv_timezone ).
      CATCH zcx_param ##NO_HANDLER.
        " ไม่มี param หรือค่าลง type timezone ไม่ได้
        " ปล่อย lv_timezone ว่างไว้ แล้วใช้ UTC+7 ด้านล่าง
    ENDTRY.

    IF lv_timezone IS NOT INITIAL.
      CONVERT TIME STAMP lv_timestamp
              TIME ZONE  lv_timezone
              INTO DATE  ev_date
                   TIME  ev_time.
      ev_subrc = sy-subrc.
    ENDIF.

    " ไม่มี param -> ใช้ UTC+7
    " มี param แต่ timezone ใช้ไม่ได้ (sy-subrc 8) -> ลองใหม่ด้วย UTC+7
    IF lv_timezone IS INITIAL OR ev_subrc <> 0.
      CONVERT TIME STAMP lv_timestamp
              TIME ZONE  gc_local_time_zone
              INTO DATE  ev_date
                   TIME  ev_time.
      ev_subrc = sy-subrc.
    ENDIF.

    " แปลงไม่สำเร็จ ไม่คืนวันที่หรือเวลาที่อาจผิด
    IF ev_subrc <> 0.
      CLEAR: ev_date,
             ev_time.
    ENDIF.

  ENDMETHOD.


  METHOD remove_invisible_char.

    rv_text = iv_text.

    " U+00A0 NBSP
    " U+200B-200D zero-width
    " U+FEFF BOM
    " U+3000 ideographic space
    REPLACE ALL OCCURRENCES OF PCRE `[\x{00A0}\x{200B}-\x{200D}\x{FEFF}\x{3000}]`
    IN rv_text WITH ` `.

    rv_text = condense( rv_text ).

  ENDMETHOD.

ENDCLASS.
