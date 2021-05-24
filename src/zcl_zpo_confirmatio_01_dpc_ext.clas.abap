class ZCL_ZPO_CONFIRMATIO_01_DPC_EXT definition
  public
  inheriting from ZCL_ZPO_CONFIRMATIO_01_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITYSET
    redefinition .
protected section.

  methods CONFIRM_DETAILSS_GET_ENTITYSET
    redefinition .
  methods DOCUMENT_NOSET_GET_ENTITYSET
    redefinition .
  methods LINE_ITEMSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZPO_CONFIRMATIO_01_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.
    TYPES:BEGIN OF ts_po_lineitem.
            INCLUDE TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_line_item.
            TYPES:  polineitemtoconfirmdetailsnav TYPE TABLE OF zcl_zpo_confirmatio_01_mpc_ext=>ts_confirm_details WITH DEFAULT KEY,
          END OF ts_po_lineitem.

    TYPES:BEGIN OF ts_document.
            INCLUDE TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_document_no.
            TYPES:  potolineitemnav TYPE TABLE OF ts_po_lineitem WITH DEFAULT KEY,
          END OF ts_document.

    DATA: ls_deep_document   TYPE ts_document,
          lv_ebeln           TYPE ebeln,
          ls_line_item       TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_line_item,
          lt_line_item       TYPE zcl_zpo_confirmatio_01_mpc_ext=>tt_line_item,
          ls_confirm_details TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_confirm_details,
          lt_confirm_details TYPE zcl_zpo_confirmatio_01_mpc_ext=>tt_confirm_details,
          lt_po_lineitem     TYPE TABLE OF ts_po_lineitem,
          lv_tabix           TYPE sy-tabix,
          lv_techname        TYPE string,
          lt_item            TYPE  bapimeconf_t_item,
          lt_itemx           TYPE  bapimeconf_t_itemx,
          lt_item1            TYPE  bapimeconf_t_item,
          lt_item1x           TYPE  bapimeconf_t_itemx,
          lt_confirmation    TYPE  bapimeconf_t_detail,
          lt_confirmationx   TYPE  bapimeconf_t_detailx,
          lt_return          TYPE TABLE OF bapiret2.

    io_data_provider->read_entry_data( IMPORTING es_data = ls_deep_document ).
    lv_ebeln = ls_deep_document-document_no.

    LOOP AT ls_deep_document-potolineitemnav INTO DATA(ls_lineitem).
      IF ls_lineitem-document_no IS INITIAL.
        ls_lineitem-document_no = lv_ebeln.                         "ADDED
      ENDIF.
      APPEND INITIAL LINE TO lt_item ASSIGNING FIELD-SYMBOL(<lfs_item>).
      IF <lfs_item> IS ASSIGNED.
        <lfs_item>-item_no     = ls_lineitem-item_no.
        <lfs_item>-acknowl_no  = ls_lineitem-acknowl_no.
        <lfs_item>-canceled    = ls_lineitem-canceled.
        <lfs_item>-confirmed_as_ordered = ls_lineitem-confirmed_as_ordered.
        IF ls_lineitem-confirmed_as_ordered IS NOT INITIAL AND ls_lineitem-acknowl_no IS NOT INITIAL.
          DATA(lv_ack) = 'X'.
          APPEND INITIAL LINE TO lt_item1 ASSIGNING FIELD-SYMBOL(<lfs_item1>).
          IF <lfs_item1> IS ASSIGNED.
            <lfs_item1>-item_no     = ls_lineitem-item_no.
            <lfs_item1>-acknowl_no  = ls_lineitem-acknowl_no.
            <lfs_item1>-canceled    = ls_lineitem-canceled.
          ENDIF.
        ENDIF.
      ENDIF.
      APPEND INITIAL LINE TO lt_itemx ASSIGNING FIELD-SYMBOL(<lfs_itemx>).
      IF <lfs_itemx> IS ASSIGNED.
        <lfs_itemx>-item_no     = ls_lineitem-item_no.
        <lfs_itemx>-item_nox     = abap_true.
        <lfs_itemx>-acknowl_no  = abap_true.
        IF ls_lineitem-canceled IS NOT INITIAL.
          <lfs_itemx>-canceled    = abap_true.
        ENDIF.
        IF ls_lineitem-confirmed_as_ordered IS NOT INITIAL.
          <lfs_itemx>-confirmed_as_ordered = abap_true.
        ENDIF.
        IF lv_ack IS NOT INITIAL.
          APPEND INITIAL LINE TO lt_item1x ASSIGNING FIELD-SYMBOL(<lfs_item1x>).
          IF <lfs_item1x> IS ASSIGNED.
            <lfs_item1x>-item_no     = ls_lineitem-item_no.
            <lfs_item1x>-item_nox     = abap_true.
            <lfs_item1x>-acknowl_no  = abap_true.
          ENDIF.
        ENDIF.
      ENDIF.

      IF ls_lineitem-confirmed_as_ordered NE abap_true.
*        READ TABLE ls_lineitem-polineitemtoconfirmdetailsnav TRANSPORTING NO FIELDS
*                                                             WITH KEY item_no = ls_lineitem-item_no.
*        IF sy-subrc = 0.
*          CLEAR lv_tabix.
*          lv_tabix = sy-tabix.
*          LOOP AT ls_lineitem-polineitemtoconfirmdetailsnav INTO DATA(ls_confitem) FROM lv_tabix.
        DATA(lv_seq) = 0.
        LOOP AT ls_lineitem-polineitemtoconfirmdetailsnav INTO DATA(ls_confitem).
          lv_seq = lv_seq + 1.
          IF ls_confitem-document_no IS INITIAL OR ls_confitem-item_no IS INITIAL.
            ls_confitem-document_no = lv_ebeln.                                       "ADDED check
            ls_confitem-item_no = ls_lineitem-item_no.
          ENDIF.
          IF ls_confitem-item_no <> ls_lineitem-item_no.
            EXIT.
          ELSE.
            APPEND INITIAL LINE TO lt_confirmation ASSIGNING FIELD-SYMBOL(<lfs_confirmation>).
            IF <lfs_confirmation> IS ASSIGNED.
              <lfs_confirmation>-item_no        = ls_confitem-item_no        .
              <lfs_confirmation>-conf_ser       = ls_confitem-conf_ser       .
              <lfs_confirmation>-delete_ind     = ls_confitem-delete_ind     .
              <lfs_confirmation>-conf_category  = ls_confitem-conf_category  .
              <lfs_confirmation>-deliv_date_typ = ls_confitem-deliv_date_typ .
              <lfs_confirmation>-deliv_date     = ls_confitem-deliv_date     .
              <lfs_confirmation>-deliv_time     = ls_confitem-deliv_time     .
              <lfs_confirmation>-quantity       = ls_confitem-quantity       .
              <lfs_confirmation>-reference      = ls_confitem-reference      .
              <lfs_confirmation>-batch          = ls_confitem-batch          .
              <lfs_confirmation>-creat_date     = ls_confitem-creat_date     .
              <lfs_confirmation>-creat_time     = ls_confitem-creat_time     .
              <lfs_confirmation>-mpn            = ls_confitem-mpn            .
              <lfs_confirmation>-handoverdate   = ls_confitem-handoverdate   .
              <lfs_confirmation>-handovertime   = ls_confitem-handovertime   .
              <lfs_confirmation>-msgtstmp       = ls_confitem-msgtstmp       .

            ENDIF.
            APPEND INITIAL LINE TO lt_confirmationx ASSIGNING FIELD-SYMBOL(<lfs_confirmationx>).
            IF <lfs_confirmationx> IS ASSIGNED.
              <lfs_confirmationx>-item_no        = ls_confitem-item_no       .
              <lfs_confirmationx>-item_nox       = abap_true        .
              <lfs_confirmationx>-conf_ser       = ls_confitem-conf_ser       .
              <lfs_confirmationx>-conf_serx      = abap_true       .
              <lfs_confirmationx>-delete_ind     = abap_true.
              <lfs_confirmationx>-conf_category  = abap_true.
              <lfs_confirmationx>-deliv_date_typ = abap_true.
              <lfs_confirmationx>-deliv_date     = abap_true.
              <lfs_confirmationx>-deliv_time     = abap_true.
              <lfs_confirmationx>-quantity       = abap_true.
              <lfs_confirmationx>-reference      = abap_true.
              <lfs_confirmationx>-batch          = abap_true.
              <lfs_confirmationx>-creat_date     = abap_true.
              <lfs_confirmationx>-creat_time     = abap_true.
              <lfs_confirmationx>-mpn            = abap_true.
              <lfs_confirmationx>-handoverdate   = abap_true.
              <lfs_confirmationx>-handovertime   = abap_true.
              <lfs_confirmationx>-msgtstmp       = abap_true.

            ENDIF.
          ENDIF.
          MODIFY ls_lineitem-polineitemtoconfirmdetailsnav FROM ls_confitem INDEX lv_seq. "ADDED
          CLEAR : ls_confitem.
        ENDLOOP.
      ENDIF.
      MODIFY ls_deep_document-potolineitemnav FROM ls_lineitem INDEX sy-tabix.   "ADDED
      CLEAR: ls_lineitem,lv_ack.
    ENDLOOP.

    IF lt_item1 IS NOT INITIAL.

      CALL FUNCTION 'ME_PO_CONFIRM'
        EXPORTING
          document_no = lv_ebeln
          item        = lt_item1
          itemx       = lt_item1x
*         confirmation  = lt_confirmation
*         confirmationx = lt_confirmationx
        IMPORTING
          return      = lt_return.
      READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
      IF sy-subrc = 0.
        DATA: lo_message_container
           TYPE REF TO /iwbep/if_message_container.
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
************************Error Handling Code*************************
********************************************************************
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
      ENDIF.

    ENDIF.

    CALL FUNCTION 'ME_PO_CONFIRM'
      EXPORTING
        document_no   = lv_ebeln
        item          = lt_item
        itemx         = lt_itemx
        confirmation  = lt_confirmation
        confirmationx = lt_confirmationx
      IMPORTING
        return        = lt_return.
    READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
    IF sy-subrc = 0.
*      DATA: lo_message_container
*         TYPE REF TO /iwbep/if_message_container.
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
************************Error Handling Code*************************
********************************************************************
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
    ENDIF.

    copy_data_to_ref(
         EXPORTING
                is_data = ls_deep_document
         CHANGING
                cr_data = er_deep_entity ).
  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.
    TYPES:BEGIN OF ts_po_lineitem.
            INCLUDE TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_line_item.
            TYPES:  polineitemtoconfirmdetailsnav TYPE TABLE OF zcl_zpo_confirmatio_01_mpc_ext=>ts_confirm_details WITH DEFAULT KEY,
          END OF ts_po_lineitem.

    TYPES:BEGIN OF ts_document.
            INCLUDE TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_document_no.
            TYPES:  potolineitemnav TYPE TABLE OF ts_po_lineitem WITH DEFAULT KEY,
          END OF ts_document.

    DATA: ls_deep_document TYPE ts_document, "PO-Line Item-Confirmation Line Item Data
          ls_po_lineitem   TYPE ts_po_lineitem, "Line Item-Confirmation Line Item Data
          lv_ebeln         TYPE ebeln,
          lv_ebelp         TYPE ebelp,
          lv_tabix         TYPE sy-tabix,
          lt_bstae         TYPE RANGE OF bstae,
          lv_techname      TYPE string.
    DATA: lo_message_container TYPE REF TO /iwbep/if_message_container.

    DATA lr_entity TYPE REF TO data.                        "#EC NEEDED

    SELECT 'I'   AS sign,
           'EQ'  AS option,
           bstae AS low
      INTO TABLE @lt_bstae
      FROM t163g AS a
      JOIN t163d AS b
        ON a~ebtyp = b~ebtyp
     WHERE ibtyp = '1'.

    IF it_key_tab IS NOT INITIAL.
      READ TABLE it_key_tab INTO DATA(ls_key_tab) WITH KEY name = 'DocumentNo'.
      IF sy-subrc = 0.
        lv_ebeln = ls_key_tab-value.
      ENDIF.
      READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'ItemNo'.
      IF sy-subrc = 0.
        lv_ebelp = ls_key_tab-value.
      ENDIF.
    ENDIF.
    CASE iv_entity_set_name.
      WHEN 'Document_noSet'.
        IF lv_ebeln IS NOT INITIAL.
          SELECT SINGLE ebeln INTO ls_deep_document-document_no FROM ekko WHERE ebeln = lv_ebeln.
          IF sy-subrc = 0.
            SELECT ebeln,
                   ebelp,
                   labnr,
                   abskz,
                   bstae
              FROM ekpo
              INTO TABLE @DATA(lt_ekpo)
              WHERE ebeln = @lv_ebeln
              ORDER BY PRIMARY KEY.
            IF sy-subrc = 0.
              DELETE lt_ekpo WHERE bstae EQ space
                                OR bstae NOT IN lt_bstae.

              IF lt_ekpo IS INITIAL.
************************Error Handling Code*************************
                CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
                  RECEIVING
                    ro_message_container = lo_message_container.

                CALL METHOD lo_message_container->add_message
                  EXPORTING
                    iv_msg_type   = 'E'
                    iv_msg_id     = 'ZMM'
                    iv_msg_number = '001'
                    iv_msg_text   = 'Confirmation Not Required!!!'.

                RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
                  EXPORTING
                    textid            = /iwbep/cx_mgw_busi_exception=>business_error
                    message_container = lo_message_container.
********************************************************************
              ELSE.
                SELECT ebeln,
                       ebelp,
                       etens,
                       loekz,
                       ebtyp,
                       lpein,
                       eindt,
                       uzeit,
                       menge,
                       xblnr,
                       charg,
                       erdat,
                       ezeit,
                       ematn,
                       handoverdate,
                       handovertime,
                       msgtstmp
*                     startdate,
*                     enddate,
*                     serviceperformer
                  FROM ekes
                  INTO TABLE @DATA(lt_ekes)
                  FOR ALL ENTRIES IN @lt_ekpo
                  WHERE ebeln = @lt_ekpo-ebeln
                    AND ebelp = @lt_ekpo-ebelp
                    AND ebtyp = 'AB'.
                IF sy-subrc <> 0.
*                  CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
*                    RECEIVING
*                      ro_message_container = lo_message_container.
*
*                  CALL METHOD lo_message_container->add_message
*                    EXPORTING
*                      iv_msg_type   = 'E'
*                      iv_msg_id     = 'ZMM'
*                      iv_msg_number = '002'
*                      iv_msg_text   = 'Confirmation Data does not exist!!!'.
*
*                  RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*                    EXPORTING
*                      textid            = /iwbep/cx_mgw_busi_exception=>business_error
*                      message_container = lo_message_container.
*                ENDIF.
*              ENDIF.
                  er_entity = lr_entity.
                  CLEAR: ls_deep_document,lt_ekpo,lt_ekes.
                ENDIF.
              ENDIF.
            ELSE.
************************Error Handling Code*************************
              CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
                RECEIVING
                  ro_message_container = lo_message_container.

              CALL METHOD lo_message_container->add_message
                EXPORTING
                  iv_msg_type   = 'I'
                  iv_msg_id     = 'ZMM'
                  iv_msg_number = '003'
                  iv_msg_text   = 'Purchasing Document Line Item Data do not exist!!!'.

              RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
                EXPORTING
                  textid            = /iwbep/cx_mgw_busi_exception=>business_error
                  message_container = lo_message_container.
********************************************************************
            ENDIF.
          ELSE.
************************Error Handling Code*************************
            CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
              RECEIVING
                ro_message_container = lo_message_container.

            CALL METHOD lo_message_container->add_message
              EXPORTING
                iv_msg_type   = 'E'
                iv_msg_id     = 'ZMM'
                iv_msg_number = '004'
                iv_msg_text   = 'Purchasing Document does not exist!!!'.

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_busi_exception=>business_error
                message_container = lo_message_container.
********************************************************************
          ENDIF.

          IF lt_ekes IS NOT INITIAL.
            SORT lt_ekpo BY ebeln ebelp ASCENDING.
            SORT lt_ekes BY ebeln ebelp etens ASCENDING.
            LOOP AT lt_ekpo INTO DATA(ls_ekpo).
              IF ls_ekpo-ebeln <> ls_deep_document-document_no.
                EXIT.
              ELSE.
                APPEND INITIAL LINE TO ls_deep_document-potolineitemnav ASSIGNING FIELD-SYMBOL(<lfs_lineitem>).
                IF <lfs_lineitem> IS ASSIGNED.
                  <lfs_lineitem>-document_no = ls_ekpo-ebeln.
                  <lfs_lineitem>-item_no     = ls_ekpo-ebelp.
                  <lfs_lineitem>-acknowl_no  = ls_ekpo-labnr.
                  <lfs_lineitem>-canceled    = ls_ekpo-abskz.
                  <lfs_lineitem>-confirmed_as_ordered = abap_true.
                  READ TABLE lt_ekes TRANSPORTING NO FIELDS WITH KEY ebeln = ls_ekpo-ebeln
                                                                     ebelp = ls_ekpo-ebelp.
                  IF sy-subrc = 0.
                    CLEAR lv_tabix.
                    lv_tabix = sy-tabix.
                    LOOP AT lt_ekes INTO DATA(ls_ekes) FROM lv_tabix.
                      IF ls_ekes-ebelp <> ls_ekpo-ebelp.
                        EXIT.
                      ELSE.
                        APPEND INITIAL LINE TO <lfs_lineitem>-polineitemtoconfirmdetailsnav ASSIGNING FIELD-SYMBOL(<lfs_cfrmitem>).
                        IF <lfs_cfrmitem> IS ASSIGNED.
                          <lfs_cfrmitem>-document_no    = ls_ekes-ebeln.
                          <lfs_cfrmitem>-item_no        = ls_ekes-ebelp.
                          <lfs_cfrmitem>-conf_ser       = ls_ekes-etens.
                          <lfs_cfrmitem>-delete_ind     = ls_ekes-loekz.
                          <lfs_cfrmitem>-conf_category  = ls_ekes-ebtyp.
                          <lfs_cfrmitem>-deliv_date_typ = ls_ekes-lpein.
                          <lfs_cfrmitem>-deliv_date     = ls_ekes-eindt.
                          <lfs_cfrmitem>-deliv_time     = ls_ekes-uzeit.
                          <lfs_cfrmitem>-quantity       = ls_ekes-menge.
                          <lfs_cfrmitem>-reference      = ls_ekes-xblnr.
                          <lfs_cfrmitem>-batch          = ls_ekes-charg.
                          <lfs_cfrmitem>-creat_date     = ls_ekes-erdat.
                          <lfs_cfrmitem>-creat_time     = ls_ekes-ezeit.
                          <lfs_cfrmitem>-mpn            = ls_ekes-ematn.
                          <lfs_cfrmitem>-handoverdate   = ls_ekes-handoverdate.
                          <lfs_cfrmitem>-handovertime   = ls_ekes-handovertime.
                          <lfs_cfrmitem>-msgtstmp       = ls_ekes-msgtstmp.
                        ENDIF.
                      ENDIF.
                      CLEAR ls_ekes.
                    ENDLOOP.
                  ENDIF.
                ENDIF.
              ENDIF.
              CLEAR ls_ekpo.
            ENDLOOP.
          ENDIF.
          lv_techname = 'POTOLINEITEMNAV/POLINEITEMTOCONFIRMDETAILSNAV'.
          APPEND lv_techname TO et_expanded_tech_clauses.

          IF ls_deep_document IS NOT INITIAL.
            copy_data_to_ref( EXPORTING is_data = ls_deep_document
                              CHANGING cr_data = er_entity ).
          ENDIF.
        ENDIF.
      WHEN 'Line_ItemSet'.
        IF lv_ebeln IS NOT INITIAL AND lv_ebelp IS NOT INITIAL.
          SELECT SINGLE ebeln INTO ls_po_lineitem-document_no FROM ekko WHERE ebeln = lv_ebeln.
          IF sy-subrc = 0.
            SELECT SINGLE ebeln,
                   ebelp,
                   labnr,
                   abskz
              FROM ekpo
              INTO @ls_ekpo
              WHERE ebeln = @lv_ebeln
                AND ebelp = @lv_ebelp.
            IF sy-subrc = 0.
              IF ls_ekpo-bstae NOT IN lt_bstae.
*******************************Error Handling Code*************************
                CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
                  RECEIVING
                    ro_message_container = lo_message_container.

                CALL METHOD lo_message_container->add_message
                  EXPORTING
                    iv_msg_type   = 'E'
                    iv_msg_id     = 'ZMM'
                    iv_msg_number = '001'
                    iv_msg_text   = 'Confirmation Not Required!!!'.

                RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
                  EXPORTING
                    textid            = /iwbep/cx_mgw_busi_exception=>business_error
                    message_container = lo_message_container.
********************************************************************
              ELSE.
                SELECT ebeln,
                       ebelp,
                       etens,
                       loekz,
                       ebtyp,
                       lpein,
                       eindt,
                       uzeit,
                       menge,
                       xblnr,
                       charg,
                       erdat,
                       ezeit,
                       ematn,
                       handoverdate,
                       handovertime,
                       msgtstmp
*                     startdate,
*                     enddate,
*                     serviceperformer
                  FROM ekes
                  INTO TABLE @lt_ekes
                  WHERE ebeln = @ls_ekpo-ebeln
                    AND ebelp = @ls_ekpo-ebelp
                    AND ebtyp = 'AB'.
                IF sy-subrc <> 0.
*                  CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
*                    RECEIVING
*                      ro_message_container = lo_message_container.
*
*                  CALL METHOD lo_message_container->add_message
*                    EXPORTING
*                      iv_msg_type   = 'E'
*                      iv_msg_id     = 'ZMM'
*                      iv_msg_number = '002'
*                      iv_msg_text   = 'Confirmation Data does not exist!!!'.
*
*                  RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*                    EXPORTING
*                      textid            = /iwbep/cx_mgw_busi_exception=>business_error
*                      message_container = lo_message_container.
                  er_entity = lr_entity.
                  CLEAR: ls_deep_document,lt_ekpo,lt_ekes.
                ENDIF.
              ENDIF.
            ELSE.
************************Error Handling Code*************************
              CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
                RECEIVING
                  ro_message_container = lo_message_container.

              CALL METHOD lo_message_container->add_message
                EXPORTING
                  iv_msg_type   = 'E'
                  iv_msg_id     = 'ZMM'
                  iv_msg_number = '004'
                  iv_msg_text   = 'Purchasing Document Line Item Data do not exist!!!'.

              RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
                EXPORTING
                  textid            = /iwbep/cx_mgw_busi_exception=>business_error
                  message_container = lo_message_container.
********************************************************************
            ENDIF.
          ELSE.
************************Error Handling Code*************************
            CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
              RECEIVING
                ro_message_container = lo_message_container.
            CALL METHOD lo_message_container->add_message
              EXPORTING
                iv_msg_type   = 'E'
                iv_msg_id     = 'ZMM'
                iv_msg_number = '003'
                iv_msg_text   = 'Purchasing Document does not exist!!!'.
            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_busi_exception=>business_error
                message_container = lo_message_container.
********************************************************************
          ENDIF.
          SORT lt_ekes BY ebeln ebelp etens ASCENDING.
          ls_po_lineitem-document_no = ls_ekpo-ebeln.
          ls_po_lineitem-item_no     = ls_ekpo-ebelp.
          ls_po_lineitem-acknowl_no  = ls_ekpo-labnr.
          ls_po_lineitem-canceled    = ls_ekpo-abskz.
          ls_po_lineitem-confirmed_as_ordered = abap_true.
          LOOP AT lt_ekes INTO ls_ekes FROM lv_tabix.
            APPEND INITIAL LINE TO ls_po_lineitem-polineitemtoconfirmdetailsnav ASSIGNING <lfs_cfrmitem>.
            IF <lfs_cfrmitem> IS ASSIGNED.
              <lfs_cfrmitem>-document_no    = ls_ekes-ebeln.
              <lfs_cfrmitem>-item_no        = ls_ekes-ebelp.
              <lfs_cfrmitem>-conf_ser       = ls_ekes-etens.
              <lfs_cfrmitem>-delete_ind     = ls_ekes-loekz.
              <lfs_cfrmitem>-conf_category  = ls_ekes-ebtyp.
              <lfs_cfrmitem>-deliv_date_typ = ls_ekes-lpein.
              <lfs_cfrmitem>-deliv_date     = ls_ekes-eindt.
              <lfs_cfrmitem>-deliv_time     = ls_ekes-uzeit.
              <lfs_cfrmitem>-quantity       = ls_ekes-menge.
              <lfs_cfrmitem>-reference      = ls_ekes-xblnr.
              <lfs_cfrmitem>-batch          = ls_ekes-charg.
              <lfs_cfrmitem>-creat_date     = ls_ekes-erdat.
              <lfs_cfrmitem>-creat_time     = ls_ekes-ezeit.
              <lfs_cfrmitem>-mpn            = ls_ekes-ematn.
              <lfs_cfrmitem>-handoverdate   = ls_ekes-handoverdate.
              <lfs_cfrmitem>-handovertime   = ls_ekes-handovertime.
              <lfs_cfrmitem>-msgtstmp       = ls_ekes-msgtstmp.
            ENDIF.
            CLEAR ls_ekes.
          ENDLOOP.

          lv_techname = 'POLINEITEMTOCONFIRMDETAILSNAV'.
          APPEND lv_techname TO et_expanded_tech_clauses.

          IF ls_po_lineitem IS NOT INITIAL.
            copy_data_to_ref( EXPORTING is_data = ls_po_lineitem
                              CHANGING cr_data = er_entity ).
          ENDIF.
        ENDIF.
    ENDCASE.
  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entityset.
    TYPES:BEGIN OF ts_po_lineitem.
            INCLUDE TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_line_item.
            TYPES:  polineitemtoconfirmdetailsnav TYPE TABLE OF zcl_zpo_confirmatio_01_mpc_ext=>ts_confirm_details WITH DEFAULT KEY,
          END OF ts_po_lineitem.

    TYPES:BEGIN OF ts_document.
            INCLUDE TYPE zcl_zpo_confirmatio_01_mpc_ext=>ts_document_no.
            TYPES:  potolineitemnav TYPE TABLE OF ts_po_lineitem WITH DEFAULT KEY,
          END OF ts_document.

    DATA: ls_deep_document TYPE ts_document,
          lt_deep_document TYPE TABLE OF ts_document,
          ls_po_lineitem   TYPE ts_po_lineitem,
          lt_po_lineitem   TYPE TABLE OF ts_po_lineitem,
          lt_final         TYPE TABLE OF ts_document,
          lt_final1        TYPE TABLE OF ts_po_lineitem,
          lt_ebeln         TYPE RANGE OF ebeln,
          lt_ebelp         TYPE RANGE OF ebelp,
          ls_ebeln         LIKE LINE OF lt_ebeln,
          ls_ebelp         LIKE LINE OF lt_ebelp,
          lv_tabix1        TYPE sy-tabix,
          lv_tabix2        TYPE sy-tabix,
          lt_bstae         TYPE RANGE OF bstae,
          lv_techname      TYPE string,
          lv_tab_size      TYPE i.
    DATA: lo_message_container
             TYPE REF TO /iwbep/if_message_container.

    SELECT 'I'   AS sign,
           'EQ'  AS option,
           bstae AS low
      INTO TABLE @lt_bstae
      FROM t163g AS a
      JOIN t163d AS b
        ON a~ebtyp = b~ebtyp
     WHERE ibtyp = '1'.

    CASE iv_entity_set_name.
      WHEN 'Document_noSet'.

        READ TABLE it_filter_select_options
        INTO DATA(ls_filter)
        WITH KEY property = 'DocumentNo'.

        IF sy-subrc = 0.
          LOOP AT ls_filter-select_options INTO DATA(ls_select_options).
            ls_ebeln-sign = ls_select_options-sign.
            ls_ebeln-option = ls_select_options-option.
            ls_ebeln-low = ls_select_options-low.
            ls_ebeln-high = ls_select_options-high.
            APPEND ls_ebeln TO lt_ebeln.
            CLEAR:ls_ebeln, ls_select_options.
          ENDLOOP.
        ENDIF.

        IF lt_ebeln IS NOT INITIAL.
          SELECT ebeln INTO TABLE @DATA(lt_ekko) FROM ekko WHERE ebeln IN @lt_ebeln.
        ELSE.
          SELECT ebeln INTO TABLE @lt_ekko FROM ekko.

        ENDIF.
        IF sy-subrc = 0.
          SELECT ebeln,
                 ebelp,
                 labnr,
                 abskz,
                 bstae
            FROM ekpo
            INTO TABLE @DATA(lt_ekpo)
            FOR ALL ENTRIES IN @lt_ekko
            WHERE ebeln = @lt_ekko-ebeln
            ORDER BY PRIMARY KEY.
          IF sy-subrc = 0.
            DELETE lt_ekpo WHERE bstae EQ space
                              OR bstae NOT IN lt_bstae.

            IF lt_ekpo IS INITIAL.
************************Error Handling Code*************************
              CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
                RECEIVING
                  ro_message_container = lo_message_container.

              CALL METHOD lo_message_container->add_message
                EXPORTING
                  iv_msg_type   = 'E'
                  iv_msg_id     = 'ZMM'
                  iv_msg_number = '001'
                  iv_msg_text   = 'Confirmation Not Required!!!'.

              RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
                EXPORTING
                  textid            = /iwbep/cx_mgw_busi_exception=>business_error
                  message_container = lo_message_container.

            ELSE.
              SELECT ebeln,
                     ebelp,
                     etens,
                     loekz,
                     ebtyp,
                     lpein,
                     eindt,
                     uzeit,
                     menge,
                     xblnr,
                     charg,
                     erdat,
                     ezeit,
                     ematn,
                     handoverdate,
                     handovertime,
                     msgtstmp
                FROM ekes
                INTO TABLE @DATA(lt_ekes)
                FOR ALL ENTRIES IN @lt_ekpo
                WHERE ebeln = @lt_ekpo-ebeln
                  AND ebelp = @lt_ekpo-ebelp
                  AND ebtyp = 'AB'.
              IF sy-subrc <> 0.
*                CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
*                  RECEIVING
*                    ro_message_container = lo_message_container.
*
*                CALL METHOD lo_message_container->add_message
*                  EXPORTING
*                    iv_msg_type   = 'E'
*                    iv_msg_id     = 'ZMM'
*                    iv_msg_number = '002'
*                    iv_msg_text   = 'Confirmation Data does not exist!!!'.
*
*                RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*                  EXPORTING
*                    textid            = /iwbep/cx_mgw_busi_exception=>business_error
*                    message_container = lo_message_container.
              ENDIF.
            ENDIF.
          ELSE.
            CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
              RECEIVING
                ro_message_container = lo_message_container.

            CALL METHOD lo_message_container->add_message
              EXPORTING
                iv_msg_type   = 'E'
                iv_msg_id     = 'ZMM'
                iv_msg_number = '003'
                iv_msg_text   = 'Purchasing Document Line Item Data do not exist!!!'.

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_busi_exception=>business_error
                message_container = lo_message_container.
          ENDIF.
        ELSE.
          CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
            RECEIVING
              ro_message_container = lo_message_container.

          CALL METHOD lo_message_container->add_message
            EXPORTING
              iv_msg_type   = 'E'
              iv_msg_id     = 'ZMM'
              iv_msg_number = '004'
              iv_msg_text   = 'Purchasing Document does not exist!!!'.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_busi_exception=>business_error
              message_container = lo_message_container.
        ENDIF.
*  ENDIF.
        SORT lt_ekko BY ebeln ASCENDING.
        SORT lt_ekpo BY ebeln ebelp ASCENDING.
        SORT lt_ekes BY ebeln ebelp etens ASCENDING.
        LOOP AT lt_ekko INTO DATA(ls_ekko).
          ls_deep_document-document_no = ls_ekko-ebeln.
          READ TABLE lt_ekpo TRANSPORTING NO FIELDS WITH KEY ebeln = ls_ekko-ebeln.
          IF sy-subrc = 0.
            CLEAR lv_tabix1.
            lv_tabix1 = sy-tabix.
            LOOP AT lt_ekpo INTO DATA(ls_ekpo) FROM lv_tabix1.
              IF ls_ekpo-ebeln <> ls_ekko-ebeln.
                EXIT.
              ELSE.
                APPEND INITIAL LINE TO ls_deep_document-potolineitemnav ASSIGNING FIELD-SYMBOL(<lfs_lineitem>).
                IF <lfs_lineitem> IS ASSIGNED.
                  <lfs_lineitem>-document_no = ls_ekpo-ebeln.
                  <lfs_lineitem>-item_no     = ls_ekpo-ebelp.
                  <lfs_lineitem>-acknowl_no  = ls_ekpo-labnr.
                  <lfs_lineitem>-canceled    = ls_ekpo-abskz.
*                  <lfs_lineitem>-confirmed_as_ordered = abap_true.
                  READ TABLE lt_ekes TRANSPORTING NO FIELDS WITH KEY ebeln = ls_ekpo-ebeln
                                                                     ebelp = ls_ekpo-ebelp.
                  IF sy-subrc = 0.
                    CLEAR lv_tabix2.
                    lv_tabix2 = sy-tabix.
                    LOOP AT lt_ekes INTO DATA(ls_ekes) FROM lv_tabix2.
                      IF ls_ekes-ebelp <> ls_ekpo-ebelp.
                        EXIT.
                      ELSE.
                        APPEND INITIAL LINE TO <lfs_lineitem>-polineitemtoconfirmdetailsnav ASSIGNING FIELD-SYMBOL(<lfs_cfrmitem>).
                        IF <lfs_cfrmitem> IS ASSIGNED.
                          <lfs_cfrmitem>-document_no    = ls_ekes-ebeln.
                          <lfs_cfrmitem>-item_no        = ls_ekes-ebelp.
                          <lfs_cfrmitem>-conf_ser       = ls_ekes-etens.
                          <lfs_cfrmitem>-delete_ind     = ls_ekes-loekz.
                          <lfs_cfrmitem>-conf_category  = ls_ekes-ebtyp.
                          <lfs_cfrmitem>-deliv_date_typ = ls_ekes-lpein.
                          <lfs_cfrmitem>-deliv_date     = ls_ekes-eindt.
                          <lfs_cfrmitem>-deliv_time     = ls_ekes-uzeit.
                          <lfs_cfrmitem>-quantity       = ls_ekes-menge.
                          <lfs_cfrmitem>-reference      = ls_ekes-xblnr.
                          <lfs_cfrmitem>-batch          = ls_ekes-charg.
                          <lfs_cfrmitem>-creat_date     = ls_ekes-erdat.
                          <lfs_cfrmitem>-creat_time     = ls_ekes-ezeit.
                          <lfs_cfrmitem>-mpn            = ls_ekes-ematn.
                          <lfs_cfrmitem>-handoverdate   = ls_ekes-handoverdate.
                          <lfs_cfrmitem>-handovertime   = ls_ekes-handovertime.
                          <lfs_cfrmitem>-msgtstmp       = ls_ekes-msgtstmp.
*                          <lfs_cfrmitem>-startdate      = ls_ekes-startdate.
*                          <lfs_cfrmitem>-enddate        = ls_ekes-enddate.
*                          <lfs_cfrmitem>-serviceperformer = ls_ekes-serviceperformer.
                        ENDIF.
                      ENDIF.
                      CLEAR ls_ekes.
                    ENDLOOP.
                  ENDIF.
                ENDIF.
              ENDIF.
              CLEAR ls_ekpo.
            ENDLOOP.
          ENDIF.
          APPEND ls_deep_document TO lt_deep_document.
          CLEAR:ls_ekko,ls_deep_document.
        ENDLOOP.

        IF is_paging-top IS NOT INITIAL OR
        is_paging-skip IS NOT INITIAL.
          LOOP AT lt_deep_document INTO ls_deep_document.
            IF sy-tabix > is_paging-skip.
              APPEND ls_deep_document TO lt_final.
              lv_tab_size = lines( lt_final ).
              IF is_paging-top IS NOT INITIAL AND
                 lv_tab_size >= is_paging-top.
                EXIT.
              ENDIF.
            ENDIF.
            CLEAR ls_deep_document.
          ENDLOOP.
          CLEAR lt_deep_document.
          lt_deep_document = lt_final.
        ENDIF.

        lv_techname = 'POTOLINEITEMNAV/POLINEITEMTOCONFIRMDETAILSNAV'.
        APPEND lv_techname TO et_expanded_tech_clauses.

* $inlinecount query option
        IF io_tech_request_context->has_inlinecount( ) = abap_true.
          DESCRIBE TABLE lt_deep_document LINES es_response_context-inlinecount.
        ELSE.
          CLEAR es_response_context-inlinecount.
        ENDIF.

        IF lt_deep_document IS NOT INITIAL.
          copy_data_to_ref( EXPORTING is_data = lt_deep_document
                            CHANGING cr_data = er_entityset ).
        ENDIF.

      WHEN 'Line_ItemSet'.

        READ TABLE it_filter_select_options
        INTO DATA(ls_filter1)
        WITH KEY property = 'DocumentNo'.

        IF sy-subrc = 0.
          LOOP AT ls_filter1-select_options INTO ls_select_options.
            ls_ebeln-sign = ls_select_options-sign.
            ls_ebeln-option = ls_select_options-option.
            ls_ebeln-low = ls_select_options-low.
            ls_ebeln-high = ls_select_options-high.
            APPEND ls_ebeln TO lt_ebeln.
            CLEAR:ls_ebeln, ls_select_options.
          ENDLOOP.
        ENDIF.

        CLEAR ls_filter1.

        READ TABLE it_filter_select_options
        INTO DATA(ls_filter2)
        WITH KEY property = 'ItemNo'.

        IF sy-subrc = 0.
          LOOP AT ls_filter2-select_options INTO ls_select_options.
            ls_ebelp-sign = ls_select_options-sign.
            ls_ebelp-option = ls_select_options-option.
            ls_ebelp-low = ls_select_options-low.
            ls_ebelp-high = ls_select_options-high.
            APPEND ls_ebelp TO lt_ebelp.
            CLEAR:ls_ebelp, ls_select_options.
          ENDLOOP.
        ENDIF.

        IF lt_ebeln IS NOT INITIAL.
          SELECT ebeln INTO TABLE @lt_ekko FROM ekko WHERE ebeln IN @lt_ebeln.
        ELSE.
          SELECT ebeln INTO TABLE @lt_ekko FROM ekko.
        ENDIF.

        IF sy-subrc = 0.
          SELECT ebeln,
                 ebelp,
                 labnr,
                 abskz,
                 bstae
            FROM ekpo
            INTO TABLE @lt_ekpo
            FOR ALL ENTRIES IN @lt_ekko
            WHERE ebeln = @lt_ekko-ebeln
            AND ebelp IN @lt_ebelp.
          IF sy-subrc = 0.
            SORT lt_ekpo BY ebeln ebelp.
            DELETE lt_ekpo WHERE bstae EQ space
                              OR bstae NOT IN lt_bstae.

            IF lt_ekpo IS INITIAL.

              CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
                RECEIVING
                  ro_message_container = lo_message_container.

              CALL METHOD lo_message_container->add_message
                EXPORTING
                  iv_msg_type   = 'E'
                  iv_msg_id     = 'ZMM'
                  iv_msg_number = '001'
                  iv_msg_text   = 'Confirmation Not Required!!!'.

              RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
                EXPORTING
                  textid            = /iwbep/cx_mgw_busi_exception=>business_error
                  message_container = lo_message_container.

            ELSE.
              SELECT ebeln,
                     ebelp,
                     etens,
                     loekz,
                     ebtyp,
                     lpein,
                     eindt,
                     uzeit,
                     menge,
                     xblnr,
                     charg,
                     erdat,
                     ezeit,
                     ematn,
                     handoverdate,
                     handovertime,
                     msgtstmp
                FROM ekes
                INTO TABLE @lt_ekes
                FOR ALL ENTRIES IN @lt_ekpo
                WHERE ebeln = @lt_ekpo-ebeln
                  AND ebelp = @lt_ekpo-ebelp
                  AND ebtyp = 'AB'.
              IF sy-subrc <> 0.
*                CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
*                  RECEIVING
*                    ro_message_container = lo_message_container.
*
*                CALL METHOD lo_message_container->add_message
*                  EXPORTING
*                    iv_msg_type   = 'E'
*                    iv_msg_id     = 'ZMM'
*                    iv_msg_number = '002'
*                    iv_msg_text   = 'Confirmation Data does not exist!!!'.
*
*                RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*                  EXPORTING
*                    textid            = /iwbep/cx_mgw_busi_exception=>business_error
*                    message_container = lo_message_container.
              ENDIF.
            ENDIF.
          ELSE.
            CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
              RECEIVING
                ro_message_container = lo_message_container.

            CALL METHOD lo_message_container->add_message
              EXPORTING
                iv_msg_type   = 'E'
                iv_msg_id     = 'ZMM'
                iv_msg_number = '003'
                iv_msg_text   = 'Purchasing Document Line Item Data do not exist!!!'.

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_busi_exception=>business_error
                message_container = lo_message_container.
          ENDIF.
        ELSE.
          CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
            RECEIVING
              ro_message_container = lo_message_container.
          CALL METHOD lo_message_container->add_message
            EXPORTING
              iv_msg_type   = 'E'
              iv_msg_id     = 'ZMM'
              iv_msg_number = '004'
              iv_msg_text   = 'Purchasing Document does not exist!!!'.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_busi_exception=>business_error
              message_container = lo_message_container.
        ENDIF.

*        SORT lt_ekko BY ebeln ASCENDING.
        SORT lt_ekpo BY ebeln ebelp ASCENDING.
        SORT lt_ekes BY ebeln ebelp etens ASCENDING.

        LOOP AT lt_ekpo INTO ls_ekpo.
          ls_po_lineitem-document_no = ls_ekpo-ebeln.
          ls_po_lineitem-item_no     = ls_ekpo-ebelp.
          ls_po_lineitem-acknowl_no  = ls_ekpo-labnr.
          ls_po_lineitem-canceled    = ls_ekpo-abskz.
*          ls_po_lineitem-confirmed_as_ordered = abap_true.

          READ TABLE lt_ekes TRANSPORTING NO FIELDS WITH KEY ebeln = ls_ekpo-ebeln
          ebelp = ls_ekpo-ebelp.
          IF sy-subrc = 0.
            CLEAR lv_tabix1.
            lv_tabix1 = sy-tabix.
            LOOP AT lt_ekes INTO ls_ekes FROM lv_tabix1.
              IF ls_ekes-ebelp <> ls_ekpo-ebelp.
                EXIT.
              ELSE.
*          LOOP AT lt_ekes INTO ls_ekes FROM lv_tabix.
                APPEND INITIAL LINE TO ls_po_lineitem-polineitemtoconfirmdetailsnav ASSIGNING <lfs_cfrmitem>.
                IF <lfs_cfrmitem> IS ASSIGNED.
                  <lfs_cfrmitem>-document_no    = ls_ekes-ebeln.
                  <lfs_cfrmitem>-item_no        = ls_ekes-ebelp.
                  <lfs_cfrmitem>-conf_ser       = ls_ekes-etens.
                  <lfs_cfrmitem>-delete_ind     = ls_ekes-loekz.
                  <lfs_cfrmitem>-conf_category  = ls_ekes-ebtyp.
                  <lfs_cfrmitem>-deliv_date_typ = ls_ekes-lpein.
                  <lfs_cfrmitem>-deliv_date     = ls_ekes-eindt.
                  <lfs_cfrmitem>-deliv_time     = ls_ekes-uzeit.
                  <lfs_cfrmitem>-quantity       = ls_ekes-menge.
                  <lfs_cfrmitem>-reference      = ls_ekes-xblnr.
                  <lfs_cfrmitem>-batch          = ls_ekes-charg.
                  <lfs_cfrmitem>-creat_date     = ls_ekes-erdat.
                  <lfs_cfrmitem>-creat_time     = ls_ekes-ezeit.
                  <lfs_cfrmitem>-mpn            = ls_ekes-ematn.
                  <lfs_cfrmitem>-handoverdate   = ls_ekes-handoverdate.
                  <lfs_cfrmitem>-handovertime   = ls_ekes-handovertime.
                  <lfs_cfrmitem>-msgtstmp       = ls_ekes-msgtstmp.
*              <lfs_cfrmitem>-startdate      = ls_ekes-startdate.
*              <lfs_cfrmitem>-enddate        = ls_ekes-enddate.
*              <lfs_cfrmitem>-serviceperformer = ls_ekes-serviceperformer.
                ENDIF.
              ENDIF.
              CLEAR ls_ekes.
            ENDLOOP.
          ENDIF.
          APPEND ls_po_lineitem TO lt_po_lineitem.
          CLEAR :ls_ekpo,ls_po_lineitem.
        ENDLOOP.

        IF is_paging-top IS NOT INITIAL OR
          is_paging-skip IS NOT INITIAL.
          LOOP AT lt_po_lineitem INTO ls_po_lineitem.
            IF sy-tabix > is_paging-skip.
              APPEND ls_po_lineitem TO lt_final1.
              lv_tab_size = lines( lt_final1 ).
              IF is_paging-top IS NOT INITIAL AND
                 lv_tab_size >= is_paging-top.
                EXIT.
              ENDIF.
            ENDIF.
            CLEAR ls_po_lineitem.
          ENDLOOP.
          CLEAR lt_po_lineitem.
          lt_po_lineitem = lt_final1.
        ENDIF.

        lv_techname = 'POLINEITEMTOCONFIRMDETAILSNAV'.
        APPEND lv_techname TO et_expanded_tech_clauses.

* $inlinecount query option
        IF io_tech_request_context->has_inlinecount( ) = abap_true.
          DESCRIBE TABLE lt_po_lineitem LINES es_response_context-inlinecount.
        ELSE.
          CLEAR es_response_context-inlinecount.
        ENDIF.

        IF lt_po_lineitem IS NOT INITIAL.
          copy_data_to_ref( EXPORTING is_data = lt_po_lineitem
                            CHANGING cr_data = er_entityset ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.


  method CONFIRM_DETAILSS_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->CONFIRM_DETAILSS_GET_ENTITYSET
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


  method DOCUMENT_NOSET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->DOCUMENT_NOSET_GET_ENTITYSET
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


  method LINE_ITEMSET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->LINE_ITEMSET_GET_ENTITYSET
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
