"! Utility กลางของทุก RICEFW
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

    "! อ่าน token response ของ Salesforce
    "! ถ้าสำเร็จ คืน access_token + instance_url
    "! ถ้าไม่สำเร็จ คืน error + error_description
    "! แยกออกมาสำหรับให้ทดสอบได้โดยไม่ต่อไปที่ Salesforce
    CLASS-METHODS parse_sfdc_token_response
      IMPORTING iv_json          TYPE string
                iv_http_status   TYPE i
      RETURNING VALUE(rs_result) TYPE ty_sfdc_token_result.

  PRIVATE SECTION.

    CONSTANTS:
      "! Communication Scenario + Outbound Service กลางสำหรับขอ Token แบบ Basic Auth.
      gc_sfdc_comm_scenario TYPE sxco_cds_object_name VALUE 'ZCS_SFDC_TOKEN',
      gc_sfdc_service_id    TYPE c LENGTH 40          VALUE 'ZBC_SFDC_TOKEN_REST',
      gc_sfdc_path_token    TYPE string               VALUE '/services/oauth2/token',
      gc_http_ok            TYPE i                    VALUE 200.

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

ENDCLASS.
