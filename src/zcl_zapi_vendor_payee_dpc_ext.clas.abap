class ZCL_ZAPI_VENDOR_PAYEE_DPC_EXT definition
  public
  inheriting from ZCL_ZAPI_VENDOR_PAYEE_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
protected section.

  methods PERMITTEDPAYEESE_GET_ENTITY
    redefinition .
  methods PERMITTEDPAYEESE_GET_ENTITYSET
    redefinition .
  methods VENDORDATASET_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZAPI_VENDOR_PAYEE_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.

    TYPES:BEGIN OF ts_document.
            INCLUDE TYPE zcl_zapi_vendor_payee_mpc_ext=>ts_vendordata.
            TYPES : vendortopayeenav TYPE TABLE OF zcl_zapi_vendor_payee_mpc_ext=>ts_permittedpayee WITH DEFAULT KEY,
          END OF ts_document.

    DATA: ls_deep_document TYPE ts_document,
          lv_techname      TYPE string.
    DATA: lo_message_container TYPE REF TO /iwbep/if_message_container.

    DATA : tt_pp TYPE zcl_zapi_vendor_payee_mpc_ext=>tt_permittedpayee.

    IF it_key_tab IS NOT INITIAL.
      DATA(lv_lifnr) =  it_key_tab[ name = 'Vendor' ]-value.
    ENDIF.
    ls_deep_document-vendor = lv_lifnr.
    lv_lifnr = CONV lifnr( |{ lv_lifnr ALPHA = IN }| ).

    CASE iv_entity_set_name.
      WHEN 'VendorDataSet'.
        IF lv_lifnr IS NOT INITIAL.

          SELECT SINGLE lifnr FROM lfa1 INTO @DATA(lv_vendor) WHERE lifnr = @lv_lifnr.
          IF sy-subrc = 0.
            SELECT
                   empfk
              FROM lfza
              INTO TABLE @tt_pp
              WHERE lifnr = @lv_lifnr
              ORDER BY PRIMARY KEY.
            IF sy-subrc <> 0.
*                'No Permitted Payee Exist'.
            ENDIF.

            ls_deep_document-vendortopayeenav = tt_pp.

            lv_techname = 'VENDORTOPAYEENAV'.
            APPEND lv_techname TO et_expanded_tech_clauses.

            IF ls_deep_document IS NOT INITIAL.
              copy_data_to_ref( EXPORTING is_data = ls_deep_document
                                CHANGING cr_data = er_entity ).
            ENDIF.
          ELSE.

*            'Please check the Lifnr No'.
          ENDIF.
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  method PERMITTEDPAYEESE_GET_ENTITY.
**TRY.
*CALL METHOD SUPER->PERMITTEDPAYEESE_GET_ENTITY
*  EXPORTING
*    IV_ENTITY_NAME          =
*    IV_ENTITY_SET_NAME      =
*    IV_SOURCE_NAME          =
*    IT_KEY_TAB              =
**    io_request_object       =
**    io_tech_request_context =
*    IT_NAVIGATION_PATH      =
**  IMPORTING
**    er_entity               =
**    es_response_context     =
*    .
** CATCH /iwbep/cx_mgw_busi_exception .
** CATCH /iwbep/cx_mgw_tech_exception .
**ENDTRY.
  endmethod.


  method PERMITTEDPAYEESE_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->PERMITTEDPAYEESE_GET_ENTITYSET
*  EXPORTING
*    IV_ENTITY_NAME           =
*    IV_ENTITY_SET_NAME       =
*    IV_SOURCE_NAME           =
*    IT_FILTER_SELECT_OPTIONS =
*    IS_PAGING                =
*    IT_KEY_TAB               =
*    IT_NAVIGATION_PATH       =
*    IT_ORDER                 =
*    IV_FILTER_STRING         =
*    IV_SEARCH_STRING         =
**    io_tech_request_context  =
**  IMPORTING
**    et_entityset             =
**    es_response_context      =
*    .
** CATCH /iwbep/cx_mgw_busi_exception .
** CATCH /iwbep/cx_mgw_tech_exception .
**ENDTRY.
  endmethod.


  METHOD vendordataset_get_entity.
**TRY.
*CALL METHOD SUPER->VENDORDATASET_GET_ENTITY
*  EXPORTING
*    IV_ENTITY_NAME          =
*    IV_ENTITY_SET_NAME      =
*    IV_SOURCE_NAME          =
*    IT_KEY_TAB              =
**    io_request_object       =
**    io_tech_request_context =
*    IT_NAVIGATION_PATH      =
**  IMPORTING
**    er_entity               =
**    es_response_context     =
*    .
** CATCH /iwbep/cx_mgw_busi_exception .
** CATCH /iwbep/cx_mgw_tech_exception .
**ENDTRY.

*    DATA : tt_pp TYPE zcl_zapi_vendor_payee_mpc_ext=>tt_permittedpayee.
*
*    DATA(lv_lifnr) =  it_key_tab[ name = 'Vendor' ]-value.
*    lv_lifnr = CONV lifnr( |{ lv_lifnr ALPHA = IN }| ).
*
*    er_entity-vendor = lv_lifnr.
*    SELECT empfk FROM lfza INTO TABLE @tt_pp WHERE lifnr = @lv_lifnr.
*
*    er_entity-permitted_payee = tt_pp .

  ENDMETHOD.
ENDCLASS.
