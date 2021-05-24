class ZCL_ZAPI_NON_PO_INVOIC_DPC_EXT definition
  public
  inheriting from ZCL_ZAPI_NON_PO_INVOIC_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~EXECUTE_ACTION
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
protected section.

  methods DOCUMENTHEADERSE_GET_ENTITY
    redefinition .
  methods DOCUMENTHEADERSE_GET_ENTITYSET
    redefinition .
  methods INVDOCUMENTSET_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZAPI_NON_PO_INVOIC_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.

    TYPES:BEGIN OF ts_accntpayable.
            INCLUDE TYPE zcl_zapi_non_po_invoic_mpc_ext=>ts_accountpayable.
            TYPES:  accountpayabletocurrencynav TYPE zcl_zapi_non_po_invoic_mpc_ext=>ts_currencyamount,
          END OF ts_accntpayable.

    TYPES:BEGIN OF ts_tax.
            INCLUDE TYPE zcl_zapi_non_po_invoic_mpc_ext=>ts_accounttax.
            TYPES: taxtocurrencynav TYPE zcl_zapi_non_po_invoic_mpc_ext=>ts_currencyamount,
          END OF ts_tax,

          BEGIN OF ts_glitem.
            INCLUDE TYPE zcl_zapi_non_po_invoic_mpc_ext=>ts_accountgl.
            TYPES:  gltocurramountnav TYPE TABLE OF zcl_zapi_non_po_invoic_mpc_ext=>ts_currencyamount WITH DEFAULT KEY,
*            gltotaxnav        TYPE TABLE OF zcl_zapi_non_po_invoic_mpc_ext=>ts_accounttax WITH DEFAULT KEY,
            gltotaxnav        TYPE TABLE OF ts_tax WITH DEFAULT KEY,
          END OF ts_glitem.


    TYPES:BEGIN OF ts_header.
            INCLUDE TYPE zcl_zapi_non_po_invoic_mpc_ext=>ts_documentheader.
            TYPES:  headertoaccountpayablenav TYPE ts_accntpayable,
            headertoglnav             TYPE TABLE OF ts_glitem WITH DEFAULT KEY,
          END OF ts_header.

** Odata Structures Declarations
    DATA: ls_deep_document TYPE ts_header,
          ls_acc_payble    TYPE zcl_zapi_non_po_invoic_mpc_ext=>ts_accountpayable,
          ls_curr_amnt     TYPE zcl_zapi_non_po_invoic_mpc_ext=>ts_currencyamount.
*          ls_tax1          TYPE zcl_zapi_non_po_invoic_mpc_ext=>ts_accounttax.

**  Object declarations
    DATA: lo_message_container TYPE REF TO /iwbep/if_message_container.

**  Internal table declaration
    DATA: lt_glacct  TYPE TABLE OF bapiacgl09,
          lt_vendact TYPE TABLE OF bapiacap09,
          lt_curramt TYPE TABLE OF bapiaccr09,
          lt_return  TYPE TABLE OF bapiret2,
          lt_tax     TYPE TABLE OF bapiactx09.

**BAPI Workarea and variable declaration
    DATA: lv_objtyp    TYPE bapiache09-obj_type,
          lv_objkey    TYPE bapiache09-obj_key,
          lv_objsys    TYPE bapiache09-obj_sys,
          ls_docheader TYPE bapiache09,
          ls_glacct    TYPE bapiacgl09,
          ls_curramt   TYPE bapiaccr09,
          ls_vendact   TYPE bapiacap09,
          ls_tax       TYPE bapiactx09.

    io_data_provider->read_entry_data( IMPORTING es_data = ls_deep_document ).

** Populating the header data of document
    MOVE-CORRESPONDING ls_deep_document TO ls_docheader.
*    ls_docheader-obj_type   = 'BKPFF'.
*    ls_docheader-bus_act    = 'RFBU'.
    ls_docheader-username   = sy-uname.
    ls_docheader-doc_type   = 'KR'.
    ls_docheader-doc_status = '2'.

    MOVE-CORRESPONDING ls_docheader TO ls_deep_document.

* Populating Account payable Data
    MOVE-CORRESPONDING ls_deep_document-headertoaccountpayablenav TO ls_acc_payble.
    ls_vendact-itemno_acc = ls_acc_payble-itemno_acc.
    ls_vendact-vendor_no = ls_acc_payble-vendor_no.
    ls_vendact-pmnttrms = ls_acc_payble-pmnttrms.
    ls_vendact-pymt_meth = ls_acc_payble-pymt_meth.
    ls_vendact-bline_date = ls_acc_payble-bline_date.
    ls_vendact-item_text = ls_acc_payble-item_text.
    APPEND ls_vendact TO lt_vendact.
    MOVE-CORRESPONDING ls_vendact TO ls_deep_document-headertoaccountpayablenav.
    CLEAR ls_vendact.

* Populating Account payable Currency
    MOVE-CORRESPONDING ls_deep_document-headertoaccountpayablenav-accountpayabletocurrencynav TO ls_curr_amnt.
    ls_curramt-itemno_acc = ls_acc_payble-itemno_acc.
    ls_curramt-curr_type = ls_curr_amnt-curr_type.
    ls_curramt-currency = ls_curr_amnt-currency.
    ls_curramt-amt_doccur = ls_curr_amnt-amt_doccur * -1.
    APPEND ls_curramt TO lt_curramt.
    ls_deep_document-headertoaccountpayablenav-accountpayabletocurrencynav = ls_curramt.
    CLEAR ls_curramt.

* Populating GL Items Data
    LOOP AT ls_deep_document-headertoglnav INTO DATA(ls_glitem).
      APPEND INITIAL LINE TO lt_glacct ASSIGNING FIELD-SYMBOL(<lfs_item>).
      IF <lfs_item> IS ASSIGNED.
        <lfs_item>-itemno_acc   = ls_glitem-itemno_acc.
        <lfs_item>-gl_account   = ls_glitem-gl_account.
        <lfs_item>-itemno_tax   = ls_glitem-itemno_tax.
        <lfs_item>-item_text    = ls_glitem-item_text.
        <lfs_item>-comp_code    = ls_glitem-comp_code.
        <lfs_item>-tax_code     = ls_glitem-tax_code.
        <lfs_item>-taxjurcode   = ls_glitem-taxjurcode.
        <lfs_item>-costcenter   = ls_glitem-costcenter.
        <lfs_item>-bus_area     = ls_glitem-bus_area.
        <lfs_item>-profit_ctr   = ls_glitem-profit_ctr.
        <lfs_item>-material     = ls_glitem-material.
        <lfs_item>-material_long  = ls_glitem-material_long.
        <lfs_item>-quantity     = ls_glitem-quantity.
        <lfs_item>-base_uom     = ls_glitem-base_uom.
        <lfs_item>-base_uom_iso = ls_glitem-base_uom_iso.
        <lfs_item>-inv_qty      = ls_glitem-inv_qty.

      ENDIF.

* Populating GL Items Currency Data
      READ TABLE ls_glitem-gltocurramountnav INTO ls_curr_amnt INDEX sy-index.
      IF sy-subrc = 0.
        ls_curramt-itemno_acc = ls_glitem-itemno_acc.
        ls_curramt-curr_type = ls_curr_amnt-curr_type.
        ls_curramt-currency = ls_curr_amnt-currency.
        ls_curramt-amt_doccur = ls_curr_amnt-amt_doccur.
        APPEND ls_curramt TO lt_curramt.
        MOVE-CORRESPONDING ls_curramt TO ls_curr_amnt.
        MODIFY ls_glitem-gltocurramountnav FROM ls_curr_amnt INDEX sy-index.
        CLEAR :ls_curramt.
      ENDIF.

* Populating GL Items Tax Data
      LOOP AT ls_glitem-gltotaxnav INTO DATA(ls_tax1) .

        DATA(ls_tax_curr) = ls_tax1-taxtocurrencynav.
        IF sy-subrc = 0.
*        ls_curramt-itemno_acc = lv_lines + 1.
          ls_curramt-itemno_acc = ls_tax-itemno_acc.
          ls_curramt-curr_type = ls_tax_curr-curr_type.
          ls_curramt-currency = ls_tax_curr-currency.
          ls_curramt-amt_doccur = ls_tax_curr-amt_doccur.
          ls_curramt-tax_amt = ls_tax_curr-tax_amt.
          ls_curramt-amt_base = ls_tax_curr-amt_base.
          APPEND ls_curramt TO lt_curramt.
          MOVE-CORRESPONDING ls_curramt TO ls_tax1-taxtocurrencynav.
          CLEAR ls_curramt.
        ENDIF.


*        DESCRIBE TABLE lt_curramt LINES DATA(lv_lines).
*        ls_tax-itemno_acc = lv_lines + 1.
        ls_tax-itemno_acc = ls_tax1-itemno_acc.
        ls_tax-gl_account = ls_tax1-gl_account.
        ls_tax-cond_key = ls_tax1-cond_key.
        ls_tax-acct_key = ls_tax1-acct_key.
        ls_tax-tax_code = ls_tax1-tax_code.
        ls_tax-tax_rate = ls_tax1-tax_rate.
        ls_tax-tax_date = ls_tax1-tax_date.
        ls_tax-taxjurcode = ls_tax1-taxjurcode.
        ls_tax-taxjurcode_deep = ls_tax1-taxjurcode_deep.
        ls_tax-taxjurcode_level = ls_tax1-taxjurcode_level.
        ls_tax-itemno_tax = ls_tax1-itemno_tax.
        APPEND ls_tax TO lt_tax.
        MOVE-CORRESPONDING ls_tax TO ls_tax1.
        MODIFY ls_glitem-gltotaxnav FROM ls_tax1.
        CLEAR ls_tax.

      ENDLOOP.

      MODIFY ls_deep_document-headertoglnav FROM ls_glitem.
      CLEAR ls_glitem.
    ENDLOOP.

*Park Or Check the Document Data

    IF ls_deep_document-park EQ 'X' .

      CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
        EXPORTING
          documentheader = ls_docheader
        IMPORTING
          obj_type       = lv_objtyp
          obj_key        = lv_objkey
          obj_sys        = lv_objsys
        TABLES
          accountgl      = lt_glacct
          accountpayable = lt_vendact
          accounttax     = lt_tax
          currencyamount = lt_curramt
          return         = lt_return.

      READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
      IF sy-subrc = 0.

*Error Handling Code

        CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
          RECEIVING
            ro_message_container = lo_message_container.

        LOOP AT lt_return INTO DATA(ls_return) WHERE type = 'E'.
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

      ELSE.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.


        ls_deep_document-ac_doc_no = lv_objkey+0(10).
        ls_deep_document-fisc_year = lv_objkey+15(4).


      ENDIF.

    ELSEIF ls_deep_document-simulate EQ 'X' .

      CALL FUNCTION 'BAPI_ACC_DOCUMENT_CHECK'
        EXPORTING
          documentheader = ls_docheader
        TABLES
          accountgl      = lt_glacct
          accountpayable = lt_vendact
          currencyamount = lt_curramt
          return         = lt_return.

      READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
      IF sy-subrc = 0.
        CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
          RECEIVING
            ro_message_container = lo_message_container.

        LOOP AT lt_return INTO ls_return WHERE type = 'E'.
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

      ELSE.

        CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
          RECEIVING
            ro_message_container = lo_message_container.

        READ TABLE lt_return INTO ls_return WITH KEY type = 'S'.
        IF sy-subrc = 0.

          CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
            RECEIVING
              ro_message_container = lo_message_container.

          CALL METHOD lo_message_container->add_message_text_only
            EXPORTING
              iv_msg_type               = ls_return-type
              iv_msg_text               = ls_return-message
              iv_is_leading_message     = abap_true
              iv_add_to_response_header = abap_true.

        ENDIF.

      ENDIF.

    ELSE.

      CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
        RECEIVING
          ro_message_container = lo_message_container.

      CALL METHOD lo_message_container->add_message_text_only
        EXPORTING
          iv_msg_type               = 'E'
          iv_msg_text               = 'Please select either Park or Simulate'
          iv_is_leading_message     = abap_true
          iv_add_to_response_header = abap_true.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid            = /iwbep/cx_mgw_busi_exception=>business_error
          message_container = lo_message_container.

    ENDIF.

    copy_data_to_ref(
         EXPORTING
                is_data = ls_deep_document
         CHANGING
                cr_data = er_deep_entity ).


  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~execute_action.

    DATA: ls_parameter TYPE /iwbep/s_mgw_name_value_pair.

**  Object declarations
    DATA: lo_message_container TYPE REF TO /iwbep/if_message_container.

    DATA:
      lv_e_fwnav TYPE bset-fwste,
      lv_e_fwnvv TYPE bset-fwste,
      lv_e_fwste TYPE bset-fwste,
      lv_e_fwast TYPE bset-fwste,
      it_t_mwdat TYPE STANDARD TABLE OF rtax1u15,
      lv_bukrs   TYPE bukrs,
      lv_mwskz   TYPE mwskz,
      lv_txjcd   TYPE txjcd,
      lv_waers   TYPE waers,
      lv_wrbtr   TYPE wrbtr,
      lv_err     TYPE bapi_msg,
      iv_action  TYPE /iwbep/mgw_tech_name.

    iv_action = io_tech_request_context->get_function_import_name( ).

    DATA(lt_params) = io_tech_request_context->get_parameters( ).

    IF iv_action = 'CalculateTax'. " Check what action is being requested

      IF lt_params IS NOT INITIAL.

* Read Function import parameter value

        READ TABLE lt_params INTO ls_parameter WITH KEY name = 'I_BUKRS'.

        IF sy-subrc = 0.

          lv_bukrs = ls_parameter-value.

        ENDIF.

        READ TABLE lt_params INTO ls_parameter WITH KEY name = 'I_MWSKZ'.

        IF sy-subrc = 0.

          lv_mwskz = ls_parameter-value.

        ENDIF.

        READ TABLE lt_params INTO ls_parameter WITH KEY name = 'I_TXJCD'.

        IF sy-subrc = 0.

          lv_txjcd = ls_parameter-value.

        ENDIF.

        READ TABLE lt_params INTO ls_parameter WITH KEY name = 'I_WAERS'.

        IF sy-subrc = 0.

          lv_waers = ls_parameter-value.

        ENDIF.

        READ TABLE lt_params INTO ls_parameter WITH KEY name = 'I_WRBTR'.

        IF sy-subrc = 0.

          lv_wrbtr = ls_parameter-value.

        ENDIF.

        IF  lv_bukrs IS NOT INITIAL AND lv_mwskz IS NOT INITIAL AND lv_waers IS NOT INITIAL AND lv_wrbtr IS NOT INITIAL.

          CALL FUNCTION 'CALCULATE_TAX_FROM_GROSSAMOUNT'
            EXPORTING
              i_bukrs                   = lv_bukrs
              i_mwskz                   = lv_mwskz
              i_txjcd                   = lv_txjcd
              i_waers                   = lv_waers
              i_wrbtr                   = lv_wrbtr
            IMPORTING
              e_fwnav                   = lv_e_fwnav
              e_fwnvv                   = lv_e_fwnvv
              e_fwste                   = lv_e_fwste
              e_fwast                   = lv_e_fwast
            TABLES
              t_mwdat                   = it_t_mwdat
            EXCEPTIONS
              bukrs_not_found           = 1
              country_not_found         = 2
              mwskz_not_defined         = 3
              mwskz_not_valid           = 4
              account_not_found         = 5
              different_discount_base   = 6
              different_tax_base        = 7
              txjcd_not_valid           = 8
              not_found                 = 9
              ktosl_not_found           = 10
              kalsm_not_found           = 11
              parameter_error           = 12
              knumh_not_found           = 13
              kschl_not_found           = 14
              unknown_error             = 15
              amounts_too_large_for_tax = 16
              OTHERS                    = 17.
          IF sy-subrc = 0.

* Call method copy_data_to_ref and export entity set data

            copy_data_to_ref( EXPORTING is_data = it_t_mwdat

                    CHANGING cr_data = er_data ).

          ELSE.

            IF sy-subrc = 1.
              lv_err = 'BUKRS_NOT_FOUND'.
            ELSEIF sy-subrc = 2.
              lv_err =  'COUNTRY_NOT_FOUND'.
            ELSEIF sy-subrc = 3.
              lv_err =  ' MWSKZ_NOT_DEFINED'.
            ELSEIF sy-subrc = 4.
              lv_err =  'MWSKZ_NOT_VALID '.
            ELSEIF sy-subrc = 5.
              lv_err =  'ACCOUNT_NOT_FOUND'.
            ELSEIF sy-subrc = 6.
              lv_err =  'DIFFERENT_DISCOUNT_BASE'.
            ELSEIF sy-subrc = 7.
              lv_err =  'DIFFERENT_TAX_BASE'.
            ELSEIF sy-subrc = 8.
              lv_err =  'TXJCD_NOT_VALID'.
            ELSEIF sy-subrc = 9.
              lv_err =  'COUNTRY_NOT_FOUND'.
            ELSEIF sy-subrc = 10.
              lv_err =  'KTOSL_NOT_FOUND'.
            ELSEIF sy-subrc = 11.
              lv_err =  'KALSM_NOT_FOUND'.
            ELSEIF sy-subrc = 12.
              lv_err =  'PARAMETER_ERROR'.
            ELSEIF sy-subrc = 13.
              lv_err =  'KNUMH_NOT_FOUND'.
            ELSEIF sy-subrc = 14.
              lv_err =  'KSCHL_NOT_FOUND'.
            ELSEIF sy-subrc = 15.
              lv_err =  'ERROR IN TAX CONVERSION'.
            ELSEIF sy-subrc = 16.
              lv_err =  'AMOUNTS_TOO_LARGE_FOR_TAX'.
            ELSEIF sy-subrc = 17.
              lv_err =  'ERROR IN TAX CONVERSION'.
            ENDIF.

            CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
              RECEIVING
                ro_message_container = lo_message_container.

            CALL METHOD lo_message_container->add_message_text_only
              EXPORTING
                iv_msg_type               = 'E'
                iv_msg_text               = lv_err
                iv_is_leading_message     = abap_true
                iv_add_to_response_header = abap_true.

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_busi_exception=>business_error
                message_container = lo_message_container.


          ENDIF.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY.

*  TYPES:BEGIN OF ts_po_lineitem.
*            INCLUDE TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_line_item.
*            TYPES:  polineitemtoconfirmdetailsnav TYPE TABLE OF zcl_zpo_confirmatio_01_mpc_ext=>ts_confirm_details WITH DEFAULT KEY,
*          END OF ts_po_lineitem.
*
*    TYPES:BEGIN OF ts_document.
*            INCLUDE TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_document_no.
*            TYPES:  potolineitemnav TYPE TABLE OF ts_po_lineitem WITH DEFAULT KEY,
*          END OF ts_document.
*
*    DATA: ls_deep_document TYPE ts_document,
*          lt_deep_document TYPE TABLE OF ts_document,
*          ls_po_lineitem   TYPE ts_po_lineitem,
*          lt_po_lineitem   TYPE TABLE OF ts_po_lineitem,
*          lt_final         TYPE TABLE OF ts_document,
*          lt_final1        TYPE TABLE OF ts_po_lineitem,
*          lt_ebeln         TYPE RANGE OF ebeln,
*          lt_ebelp         TYPE RANGE OF ebelp,
*          ls_ebeln         LIKE LINE OF lt_ebeln,
*          ls_ebelp         LIKE LINE OF lt_ebelp,
*          lv_tabix1        TYPE sy-tabix,
*          lv_tabix2        TYPE sy-tabix,
*          lt_bstae         TYPE RANGE OF bstae,
*          lv_techname      TYPE string,
*          lv_tab_size      TYPE i.
*    DATA: lo_message_container
*             TYPE REF TO /iwbep/if_message_container.
*
*    SELECT 'I'   AS sign,
*           'EQ'  AS option,
*           bstae AS low
*      INTO TABLE @lt_bstae
*      FROM t163g AS a
*      JOIN t163d AS b
*        ON a~ebtyp = b~ebtyp
*     WHERE ibtyp = '1'.
*
*    CASE iv_entity_set_name.
*      WHEN 'Document_noSet'.
*
*        READ TABLE it_filter_select_options
*        INTO DATA(ls_filter)
*        WITH KEY property = 'DocumentNo'.
*
*        IF sy-subrc = 0.
*          LOOP AT ls_filter-select_options INTO DATA(ls_select_options).
*            ls_ebeln-sign = ls_select_options-sign.
*            ls_ebeln-option = ls_select_options-option.
*            ls_ebeln-low = ls_select_options-low.
*            ls_ebeln-high = ls_select_options-high.
*            APPEND ls_ebeln TO lt_ebeln.
*            CLEAR:ls_ebeln, ls_select_options.
*          ENDLOOP.
*        ENDIF.
*
*        IF lt_ebeln IS NOT INITIAL.
*          SELECT ebeln INTO TABLE @DATA(lt_ekko) FROM ekko WHERE ebeln IN @lt_ebeln.
*        ELSE.
*          SELECT ebeln INTO TABLE @lt_ekko FROM ekko.
*
*        ENDIF.
*        IF sy-subrc = 0.
*          SELECT ebeln,
*                 ebelp,
*                 labnr,
*                 abskz,
*                 bstae
*            FROM ekpo
*            INTO TABLE @DATA(lt_ekpo)
*            FOR ALL ENTRIES IN @lt_ekko
*            WHERE ebeln = @lt_ekko-ebeln
*            ORDER BY PRIMARY KEY.
*          IF sy-subrc = 0.
*            DELETE lt_ekpo WHERE bstae EQ space
*                              OR bstae NOT IN lt_bstae.
*
*            IF lt_ekpo IS INITIAL.
*************************Error Handling Code*************************
*              CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
*                RECEIVING
*                  ro_message_container = lo_message_container.
*
*              CALL METHOD lo_message_container->add_message
*                EXPORTING
*                  iv_msg_type   = 'E'
*                  iv_msg_id     = 'ZMM'
*                  iv_msg_number = '001'
*                  iv_msg_text   = 'Confirmation Not Required!!!'.
*
*              RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*                EXPORTING
*                  textid            = /iwbep/cx_mgw_busi_exception=>business_error
*                  message_container = lo_message_container.
*
*            ELSE.
*              SELECT ebeln,
*                     ebelp,
*                     etens,
*                     loekz,
*                     ebtyp,
*                     lpein,
*                     eindt,
*                     uzeit,
*                     menge,
*                     xblnr,
*                     charg,
*                     erdat,
*                     ezeit,
*                     ematn,
*                     handoverdate,
*                     handovertime,
*                     msgtstmp
*                FROM ekes
*                INTO TABLE @DATA(lt_ekes)
*                FOR ALL ENTRIES IN @lt_ekpo
*                WHERE ebeln = @lt_ekpo-ebeln
*                  AND ebelp = @lt_ekpo-ebelp
*                  AND ebtyp = 'AB'.
*              IF sy-subrc <> 0.
**                CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
**                  RECEIVING
**                    ro_message_container = lo_message_container.
**
**                CALL METHOD lo_message_container->add_message
**                  EXPORTING
**                    iv_msg_type   = 'E'
**                    iv_msg_id     = 'ZMM'
**                    iv_msg_number = '002'
**                    iv_msg_text   = 'Confirmation Data does not exist!!!'.
**
**                RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
**                  EXPORTING
**                    textid            = /iwbep/cx_mgw_busi_exception=>business_error
**                    message_container = lo_message_container.
*              ENDIF.
*            ENDIF.
*          ELSE.
*            CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
*              RECEIVING
*                ro_message_container = lo_message_container.
*
*            CALL METHOD lo_message_container->add_message
*              EXPORTING
*                iv_msg_type   = 'E'
*                iv_msg_id     = 'ZMM'
*                iv_msg_number = '003'
*                iv_msg_text   = 'Purchasing Document Line Item Data do not exist!!!'.
*
*            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*              EXPORTING
*                textid            = /iwbep/cx_mgw_busi_exception=>business_error
*                message_container = lo_message_container.
*          ENDIF.
*        ELSE.
*          CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
*            RECEIVING
*              ro_message_container = lo_message_container.
*
*          CALL METHOD lo_message_container->add_message
*            EXPORTING
*              iv_msg_type   = 'E'
*              iv_msg_id     = 'ZMM'
*              iv_msg_number = '004'
*              iv_msg_text   = 'Purchasing Document does not exist!!!'.
*
*          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*            EXPORTING
*              textid            = /iwbep/cx_mgw_busi_exception=>business_error
*              message_container = lo_message_container.
*        ENDIF.
**  ENDIF.
*        SORT lt_ekko BY ebeln ASCENDING.
*        SORT lt_ekpo BY ebeln ebelp ASCENDING.
*        SORT lt_ekes BY ebeln ebelp etens ASCENDING.
*        LOOP AT lt_ekko INTO DATA(ls_ekko).
*          ls_deep_document-document_no = ls_ekko-ebeln.
*          READ TABLE lt_ekpo TRANSPORTING NO FIELDS WITH KEY ebeln = ls_ekko-ebeln.
*          IF sy-subrc = 0.
*            CLEAR lv_tabix1.
*            lv_tabix1 = sy-tabix.
*            LOOP AT lt_ekpo INTO DATA(ls_ekpo) FROM lv_tabix1.
*              IF ls_ekpo-ebeln <> ls_ekko-ebeln.
*                EXIT.
*              ELSE.
*                APPEND INITIAL LINE TO ls_deep_document-potolineitemnav ASSIGNING FIELD-SYMBOL(<lfs_lineitem>).
*                IF <lfs_lineitem> IS ASSIGNED.
*                  <lfs_lineitem>-document_no = ls_ekpo-ebeln.
*                  <lfs_lineitem>-item_no     = ls_ekpo-ebelp.
*                  <lfs_lineitem>-acknowl_no  = ls_ekpo-labnr.
*                  <lfs_lineitem>-canceled    = ls_ekpo-abskz.
**                  <lfs_lineitem>-confirmed_as_ordered = abap_true.
*                  READ TABLE lt_ekes TRANSPORTING NO FIELDS WITH KEY ebeln = ls_ekpo-ebeln
*                                                                     ebelp = ls_ekpo-ebelp.
*                  IF sy-subrc = 0.
*                    CLEAR lv_tabix2.
*                    lv_tabix2 = sy-tabix.
*                    LOOP AT lt_ekes INTO DATA(ls_ekes) FROM lv_tabix2.
*                      IF ls_ekes-ebelp <> ls_ekpo-ebelp.
*                        EXIT.
*                      ELSE.
*                        APPEND INITIAL LINE TO <lfs_lineitem>-polineitemtoconfirmdetailsnav ASSIGNING FIELD-SYMBOL(<lfs_cfrmitem>).
*                        IF <lfs_cfrmitem> IS ASSIGNED.
*                          <lfs_cfrmitem>-document_no    = ls_ekes-ebeln.
*                          <lfs_cfrmitem>-item_no        = ls_ekes-ebelp.
*                          <lfs_cfrmitem>-conf_ser       = ls_ekes-etens.
*                          <lfs_cfrmitem>-delete_ind     = ls_ekes-loekz.
*                          <lfs_cfrmitem>-conf_category  = ls_ekes-ebtyp.
*                          <lfs_cfrmitem>-deliv_date_typ = ls_ekes-lpein.
*                          <lfs_cfrmitem>-deliv_date     = ls_ekes-eindt.
*                          <lfs_cfrmitem>-deliv_time     = ls_ekes-uzeit.
*                          <lfs_cfrmitem>-quantity       = ls_ekes-menge.
*                          <lfs_cfrmitem>-reference      = ls_ekes-xblnr.
*                          <lfs_cfrmitem>-batch          = ls_ekes-charg.
*                          <lfs_cfrmitem>-creat_date     = ls_ekes-erdat.
*                          <lfs_cfrmitem>-creat_time     = ls_ekes-ezeit.
*                          <lfs_cfrmitem>-mpn            = ls_ekes-ematn.
*                          <lfs_cfrmitem>-handoverdate   = ls_ekes-handoverdate.
*                          <lfs_cfrmitem>-handovertime   = ls_ekes-handovertime.
*                          <lfs_cfrmitem>-msgtstmp       = ls_ekes-msgtstmp.
**                          <lfs_cfrmitem>-startdate      = ls_ekes-startdate.
**                          <lfs_cfrmitem>-enddate        = ls_ekes-enddate.
**                          <lfs_cfrmitem>-serviceperformer = ls_ekes-serviceperformer.
*                        ENDIF.
*                      ENDIF.
*                      CLEAR ls_ekes.
*                    ENDLOOP.
*                  ENDIF.
*                ENDIF.
*              ENDIF.
*              CLEAR ls_ekpo.
*            ENDLOOP.
*          ENDIF.
*          APPEND ls_deep_document TO lt_deep_document.
*          CLEAR:ls_ekko,ls_deep_document.
*        ENDLOOP.
*
*        IF is_paging-top IS NOT INITIAL OR
*        is_paging-skip IS NOT INITIAL.
*          LOOP AT lt_deep_document INTO ls_deep_document.
*            IF sy-tabix > is_paging-skip.
*              APPEND ls_deep_document TO lt_final.
*              lv_tab_size = lines( lt_final ).
*              IF is_paging-top IS NOT INITIAL AND
*                 lv_tab_size >= is_paging-top.
*                EXIT.
*              ENDIF.
*            ENDIF.
*            CLEAR ls_deep_document.
*          ENDLOOP.
*          CLEAR lt_deep_document.
*          lt_deep_document = lt_final.
*        ENDIF.
*
*        lv_techname = 'POTOLINEITEMNAV/POLINEITEMTOCONFIRMDETAILSNAV'.
*        APPEND lv_techname TO et_expanded_tech_clauses.
*
** $inlinecount query option
*        IF io_tech_request_context->has_inlinecount( ) = abap_true.
*          DESCRIBE TABLE lt_deep_document LINES es_response_context-inlinecount.
*        ELSE.
*          CLEAR es_response_context-inlinecount.
*        ENDIF.
*
*        IF lt_deep_document IS NOT INITIAL.
*          copy_data_to_ref( EXPORTING is_data = lt_deep_document
*                            CHANGING cr_data = er_entityset ).
*        ENDIF.
*

  endmethod.


  METHOD documentheaderse_get_entity.


  ENDMETHOD.


  method DOCUMENTHEADERSE_GET_ENTITYSET.
* DATA : ls_key_tab type it_key_tab,
*         lv_belnr TYPE rbkp-belnr.
*
** IT_KEY_TAB has key name and value
*READ TABLE it_key_tab INTO ls_key_tab
*WITH KEY name = 'Belnr'. " Case sensitive
*IF sy-subrc EQ 0.
*lv_ebeln = ls_key_tab-value.
*ENDIF.
*
** Select one PO entry
*SELECT SINGLE * FROM ekko INTO CORRESPONDING FIELDS OF er_entity
*WHERE ebeln = lv_ebeln.
  endmethod.


  METHOD invdocumentset_get_entity.
    DATA : ls_key_tab    TYPE /iwbep/s_mgw_name_value_pair,
           lt_dd07v      TYPE TABLE OF dd07v,
           lv_status(60) TYPE c,
           ls_output     TYPE zcl_zapi_non_po_invoic_mpc=>ts_invdocument.

**  Object declarations
    DATA: lo_message_container TYPE REF TO /iwbep/if_message_container.

    DATA(lv_belnr) =  it_key_tab[ name = 'AcDocNo' ]-value.
    DATA(lv_gjahr) =  it_key_tab[ name = 'FiscYear' ]-value.

* Select one Invoice entry
    SELECT SINGLE * FROM bkpf INTO @DATA(ls_bkpf)
    WHERE belnr = @lv_belnr AND gjahr = @lv_gjahr AND blart = 'KR'.

    IF ls_bkpf IS NOT INITIAL.

*      MOVE-CORRESPONDING ls_bkpf TO er_entity.

      er_entity-ac_doc_no = ls_bkpf-belnr.
      er_entity-fisc_year = ls_bkpf-gjahr.
      er_entity-fis_period = ls_bkpf-monat.
      er_entity-pstng_date = ls_bkpf-budat.
      er_entity-comp_code = ls_bkpf-bukrs.
      er_entity-bus_act = ls_bkpf-glvor.
      er_entity-username = ls_bkpf-usnam.
      er_entity-doc_type = ls_bkpf-blart.
      er_entity-ref_doc_no = ls_bkpf-xblnr.

      CALL FUNCTION 'DD_DOMVALUES_GET'
        EXPORTING
          domname        = 'BSTAT'   "<-- Your Domain Here
          text           = 'X'
          langu          = sy-langu
        TABLES
          dd07v_tab      = lt_dd07v
        EXCEPTIONS
          wrong_textflag = 1
          OTHERS         = 2.

      READ TABLE lt_dd07v ASSIGNING FIELD-SYMBOL(<ls_dd07>) WITH KEY domvalue_l = ls_bkpf-bstat.
      IF sy-subrc = 0.
        lv_status           = <ls_dd07>-ddtext.
      ENDIF.

      er_entity-status = lv_status.
      er_entity-doc_status = ls_bkpf-bstat.
      er_entity-doc_date = ls_bkpf-bldat.
      er_entity-header_txt = ls_bkpf-bktxt.
      er_entity-trans_date = ls_bkpf-wwert.
      er_entity-obj_key_r = ls_bkpf-awkey.
      er_entity-reason_rev = ls_bkpf-stgrd.
      er_entity-reverse = ls_bkpf-xreversed.
      er_entity-invoice_rec_date = ls_bkpf-reindat.
      er_entity-parking_date = ls_bkpf-ppdat.
      er_entity-parking_time = ls_bkpf-pptme.
      er_entity-parked_by = ls_bkpf-ppnam.
*
    ELSE.

     CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
        RECEIVING
          ro_message_container = lo_message_container.

      CALL METHOD lo_message_container->add_message_text_only
        EXPORTING
          iv_msg_type               = 'E'
          iv_msg_text               = 'Document Not Found'
          iv_is_leading_message     = abap_true
          iv_add_to_response_header = abap_true.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid            = /iwbep/cx_mgw_busi_exception=>business_error
          message_container = lo_message_container.


    ENDIF.
  ENDMETHOD.
ENDCLASS.
