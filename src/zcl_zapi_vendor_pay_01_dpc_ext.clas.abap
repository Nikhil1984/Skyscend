class ZCL_ZAPI_VENDOR_PAY_01_DPC_EXT definition
  public
  inheriting from ZCL_ZAPI_VENDOR_PAY_01_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
protected section.

  methods PAYEESET_GET_ENTITYSET
    redefinition .
  methods VENDORSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZAPI_VENDOR_PAY_01_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.

    TYPES:BEGIN OF ts_document.
            INCLUDE TYPE zcl_zapi_vendor_pay_01_mpc_ext=>ts_vendor.
            TYPES : vendortopayeenav TYPE TABLE OF zcl_zapi_vendor_pay_01_mpc_ext=>ts_payee WITH DEFAULT KEY,
          END OF ts_document.

    DATA: ls_deep_document TYPE ts_document.
    DATA: lo_vmd_ei_api TYPE REF TO vmd_ei_api.
    DATA: l_ti_is_master_data TYPE vmds_ei_main.
    DATA: ls_vmds_ei_extern TYPE vmds_ei_extern.
    DATA: lc_lifnr TYPE lifnr.
    DATA : ls_vmds_ei_company     TYPE vmds_ei_company,
           ls_vmds_ei_alt_payee   TYPE vmds_ei_alt_payee,
           lt_vmds_ei_company     TYPE vmds_ei_company_t,
           ls_vmds_ei_vmd_company TYPE vmds_ei_vmd_company.

*****************************************************************************
    io_data_provider->read_entry_data( IMPORTING es_data = ls_deep_document ).
    DATA(lv_lifnr) = ls_deep_document-vendor.

    CHECK lv_lifnr IS NOT INITIAL.
    CREATE OBJECT lo_vmd_ei_api.

    ls_vmds_ei_extern-header-object_instance-lifnr = lv_lifnr .
    ls_vmds_ei_extern-header-object_task = 'U'.
    ls_vmds_ei_alt_payee-task = 'I'.

    LOOP AT ls_deep_document-vendortopayeenav ASSIGNING FIELD-SYMBOL(<fs_payee>).
      IF <fs_payee>-lifnr IS INITIAL.
        <fs_payee>-lifnr = lv_lifnr.
      ELSE.
        IF <fs_payee>-lifnr <> ls_deep_document-vendor.
          EXIT.
        ENDIF.
      ENDIF.
      ls_vmds_ei_alt_payee-data_key-empfk = <fs_payee>-empfk.
      APPEND ls_vmds_ei_alt_payee TO ls_vmds_ei_company-alt_payee-alt_payee.
      CLEAR : ls_vmds_ei_alt_payee.

      ls_vmds_ei_company-task = 'U'.
      ls_vmds_ei_company-data_key-bukrs = <fs_payee>-bukrs .
      APPEND ls_vmds_ei_company TO lt_vmds_ei_company.
      CLEAR :ls_vmds_ei_company.
    ENDLOOP.

    ls_vmds_ei_vmd_company-company = lt_vmds_ei_company.

    ls_vmds_ei_extern-company_data = ls_vmds_ei_vmd_company.
    APPEND ls_vmds_ei_extern TO l_ti_is_master_data-vendors.

    CALL METHOD lo_vmd_ei_api->maintain_bapi
      EXPORTING
        is_master_data           = l_ti_is_master_data
        iv_collect_messages      = abap_true
      IMPORTING
        es_master_data_correct   = DATA(ls_es_master_data_correct)
        es_message_correct       = DATA(ls_es_message_correct)
        es_master_data_defective = DATA(ls_es_master_data_defective)
        es_message_defective     = DATA(ls_es_message_defective).

    IF ls_es_message_defective-is_error   IS INITIAL AND
       ls_es_message_defective-messages[] IS INITIAL.

      COMMIT WORK AND WAIT.

      copy_data_to_ref(
          EXPORTING
                 is_data = ls_deep_document
          CHANGING
                 cr_data = er_deep_entity ).
    ELSE.
      ROLLBACK WORK.

      DATA: lo_message_container
          TYPE REF TO /iwbep/if_message_container.
      CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
        RECEIVING
          ro_message_container = lo_message_container.
      LOOP AT ls_es_message_defective-messages[] INTO DATA(ls_return) .
        CALL METHOD lo_message_container->add_message_text_only
          EXPORTING
            iv_msg_type = ls_return-type
            iv_msg_text = ls_return-message.
        CLEAR ls_return.
      ENDLOOP.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid            = /iwbep/cx_mgw_busi_exception=>business_error
          message_container = lo_message_container.
    ENDIF.

  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.

    TYPES:BEGIN OF ts_document.
*            INCLUDE TYPE zcl_zapi_vendor_pay_01_mpc_ext=>ts_vendor.
    TYPES : vendortopayeenav TYPE TABLE OF zcl_zapi_vendor_pay_01_mpc_ext=>ts_payee WITH DEFAULT KEY,
            END OF ts_document.

    DATA: ls_deep_document TYPE ts_document,
          lv_techname      TYPE string.
    DATA: lo_message_container TYPE REF TO /iwbep/if_message_container.

    DATA : tt_pp TYPE zcl_zapi_vendor_pay_01_mpc_ext=>tt_payee.

    IF it_key_tab IS NOT INITIAL.
      DATA(lv_lifnr) =  it_key_tab[ name = 'Vendor_No' ]-value.
    ENDIF.
*    ls_deep_document-vendor = lv_lifnr.
    lv_lifnr = CONV lifnr( |{ lv_lifnr ALPHA = IN }| ).

    CASE iv_entity_set_name.
      WHEN 'VendorSet'.
        IF lv_lifnr IS NOT INITIAL.

          SELECT lifnr,
                 empfk,
                 bukrs
            FROM lfza
            INTO TABLE @tt_pp
            WHERE empfk = @lv_lifnr
            ORDER BY PRIMARY KEY.
          IF sy-subrc <> 0.
            CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
              RECEIVING
                ro_message_container = lo_message_container.

            CALL METHOD lo_message_container->add_message
              EXPORTING
                iv_msg_type   = 'E'
                iv_msg_id     = 'ZFI'
                iv_msg_number = '001'
                iv_msg_text   = 'No Permitted Payee Association Exist!!!'.

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_busi_exception=>business_error
                message_container = lo_message_container.
          ENDIF.

          ls_deep_document-vendortopayeenav = tt_pp.

          lv_techname = 'VENDORTOPAYEENAV'.
          APPEND lv_techname TO et_expanded_tech_clauses.

          IF ls_deep_document IS NOT INITIAL.
            copy_data_to_ref( EXPORTING is_data = ls_deep_document
                              CHANGING cr_data = er_entity ).
          ENDIF.
        ELSE.
          CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
            RECEIVING
              ro_message_container = lo_message_container.

          CALL METHOD lo_message_container->add_message
            EXPORTING
              iv_msg_type   = 'E'
              iv_msg_id     = 'ZFI'
              iv_msg_number = '002'
              iv_msg_text   = 'Vendor Does Not Exist!!!'.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_busi_exception=>business_error
              message_container = lo_message_container.
        ENDIF.
    ENDCASE.
  ENDMETHOD.


  method PAYEESET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->PAYEESET_GET_ENTITYSET
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


  method VENDORSET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->VENDORSET_GET_ENTITYSET
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
ENDCLASS.
