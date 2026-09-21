"! ทดสอบเฉพาะ parse — ไม่ต่อ Salesforce
CLASS ltc_utility DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    "! token response ปกติ (key ตามที่ Salesforce ส่งจริง ไม่มี expires_in)
    METHODS sfdc_token_200_is_success     FOR TESTING.
    "! 400 invalid_client → error_code + description
    METHODS sfdc_token_400_is_failure     FOR TESTING.
    "! 200 แต่ไม่มี access_token → NO_TOKEN
    METHODS sfdc_token_200_without_token  FOR TESTING.
    "! HTML แทน JSON → NO_TOKEN + เศษ body ไม่ dump
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
