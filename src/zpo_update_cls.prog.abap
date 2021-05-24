*&---------------------------------------------------------------------*
*& Include          ZCDR_UPDATE_CLS
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION.

  PUBLIC SECTION.

    METHODS : get_data,
    api_call IMPORTING iv_dest TYPE c iv_key TYPE string iv_buyer TYPE string,
     process_data
    ,timestamp IMPORTING iv_date TYPE sy-datum iv_time TYPE sy-uzeit
     RETURNING VALUE(rv_ts) TYPE string.

    DATA : lv_char TYPE char10,
           lx_msg  TYPE REF TO cx_salv_msg.

*Convert ABAP to JSON
    TYPES:BEGIN OF ty_del,
            quantity TYPE ekpo-netpr,
            due_date TYPE i,
          END OF ty_del,

          BEGIN OF ty_items,
            item_no             TYPE string,
            material_no         TYPE string,
            material_desc       TYPE string,
            plant               TYPE string,
            storage_location    TYPE string,
            quantity            TYPE ekpo-menge,
            tax                 TYPE ekpo-netpr,
            unit                TYPE string,
            price_unit          type string,
            unit_nume           TYPE ekpo-bpumz,
            unit_deno           TYPE ekpo-bpumn,
            delivery_schedule   TYPE STANDARD TABLE OF ty_del WITH EMPTY KEY,
            net_price           TYPE ekpo-netpr,
            discount            TYPE ekpo-netpr,
            status              TYPE string,
            tax_code            TYPE string,
            confirmation_key    TYPE string,
            del_completed_ind   TYPE boolean,
            final_invoice_ind   TYPE boolean,
            delivered_qty       TYPE ekpo-menge,
            still_del_qty       TYPE ekpo-menge,
            invoiced_qty        TYPE ekpo-menge,
            invoiced_value      TYPE ekpo-netpr,
            still_invoice_qty   TYPE ekpo-menge,
            still_invoice_value TYPE ekpo-netpr,
          END OF ty_items,

          BEGIN OF ty_address,
            address_line1 TYPE string,
            address_line2 TYPE string,
            city          TYPE string,
            state         TYPE string,
            country       TYPE string,
            zip           TYPE string,
          END OF ty_address.

    TYPES: BEGIN OF ty_tvarvc,
             name TYPE rvari_vnam,
             sign TYPE tvarv_sign,
             opti TYPE tvarv_opti,
             low  TYPE tvarv_val,
             high TYPE tvarv_val,
           END OF ty_tvarvc.


    TYPES: BEGIN OF ty_json_req,
             id             TYPE string,
             po_document_no TYPE string,
             company_code   TYPE string,
             payment_terms  TYPE string,
             po_org_no      TYPE string,
             po_grp         TYPE string,
             vendor_erp_id  TYPE string,
             title          TYPE string,
             status         TYPE string,
             total_cost     TYPE ekpo-netpr,
             create_ts      TYPE i,
             update_ts      TYPE i,
             currency_key   TYPE string,
             address        TYPE ty_address,
             is_deleted     TYPE boolean,
             items          TYPE STANDARD TABLE OF ty_items WITH EMPTY KEY,
           END OF ty_json_req.

    TYPES : gs_del_sch TYPE STANDARD TABLE OF ty_del WITH EMPTY KEY.

    DATA: gs_json      TYPE ty_json_req,
          gs_items     TYPE ty_items,
          gs_tvarvc    TYPE ty_tvarvc,
          ls_reference TYPE tvarvc.

ENDCLASS.

CLASS lcl_class IMPLEMENTATION.
  METHOD timestamp.
    cl_pco_utility=>convert_abap_timestamp_to_java( EXPORTING iv_date      = iv_date
                                                              iv_time      = iv_time
                                                    IMPORTING ev_timestamp =  rv_ts ).
  ENDMETHOD.

  METHOD get_data.

    DATA: lt_objid   TYPE fip_t_order_id_range,
          ls_time    TYPE range_tims,
          lv_jobname TYPE tbtcm-jobname.


    lt_objid = CORRESPONDING #( s_ebeln[] ).

    CALL FUNCTION 'GET_JOB_RUNTIME_INFO'
      IMPORTING
        jobname         = lv_jobname
      EXCEPTIONS
        no_runtime_info = 1
        OTHERS          = 2.

    IF lv_jobname CS 'ZPO_UPDATE_REPORT'.

      SELECT SINGLE name, sign, opti, low, high INTO @DATA(gs_from)
          FROM tvarvc
          WHERE name = 'ZFROM_TIME'
          AND type = 'P'.
      IF sy-subrc = 0.
        ls_time-sign = 'I'.
        ls_time-option = 'GT'.
        ls_time-high = ''.
        ls_time-low = gs_from-low.

        MODIFY s_time[] FROM ls_time INDEX 1 TRANSPORTING low.
      ENDIF.

      UPDATE tvarvc SET low = sy-uzeit WHERE name = 'ZFROM_TIME'.

    ENDIF.

**select purchase order which were created or changed
    SELECT objectid,
           change_ind,
           udate,
           utime
      INTO TABLE @t_cdhdr
      FROM cdhdr
     WHERE objectclas = 'EINKBELEG'
       AND objectid   IN @lt_objid
       AND udate      IN @s_date
       AND utime      IN @s_time.
    IF sy-subrc = 0.

**Get details of fetched purchase order
      SELECT  a~ebeln,
              b~ebelp,
              a~loekz,
              a~aedat,
              a~bukrs,
              a~lifnr,
              a~ekorg,
              a~ekgrp,
              a~waers,
              a~adrnr,
              a~ihrez,
              a~unsez,
              a~procstat,
              a~zterm,
              b~matnr,
              b~txz01,
              b~loekz,
              b~werks,
              b~lgort,
              b~menge,
              b~meins,
              b~bprme,
              b~bpumz,
              b~bpumn,
              b~netwr,
              b~mwskz,
              b~dpdat,
              b~adrn2,
              b~bstae,
              b~elikz,
              b~erekz,
              b~creationtime
        INTO TABLE @t_data
        FROM ekko AS a
        JOIN ekpo AS b
          ON a~ebeln = b~ebeln
         FOR ALL ENTRIES IN @t_cdhdr
       WHERE a~ebeln = @t_cdhdr-objectid+0(10)
         AND a~lifnr IN @s_lifnr
         AND b~repos = @abap_true.

      IF sy-subrc = 0.

        SELECT ebeln,
               ebelp,
               etenr,
               eindt,
               menge,
               uzeit
          INTO TABLE @t_eket
          FROM eket
           FOR ALL ENTRIES IN @t_data
         WHERE ebeln = @t_data-ebeln
           AND ebelp = @t_data-ebelp.
        IF sy-subrc = 0.
          SORT t_eket BY ebeln ebelp eindt DESCENDING.
        ENDIF.

        SELECT purchasingdocument,
               purchasingdocumentitem,
               goodsreceiptqty,
               stilltobedeliveredquantity,
               invoicereceiptqty,
               invoicereceiptamount,
               stilltoinvoicequantity,
               stilltoinvoicevalue
          INTO TABLE @t_poqty
          FROM i_purchasingdocumentitem AS a
          JOIN c_poitemqtyandvaluecalc  AS b
            ON a~purchasingdocument = b~purchaseorder
           AND a~purchasingdocumentitem = b~purchaseorderitem
           FOR ALL ENTRIES IN @t_data
         WHERE purchaseorder     = @t_data-ebeln
           AND purchaseorderitem = @t_data-ebelp.

        SELECT addrnumber,house_num1,street,city1,post_code1,country,region
          FROM adrc INTO TABLE @t_adrc
          FOR ALL ENTRIES IN @t_data
          WHERE addrnumber = @t_data-adrnr.

        SELECT SINGLE name sign opti low high INTO gs_tvarvc
        FROM tvarvc
        WHERE name = 'ZIHREZ'
        AND type = 'P'.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD process_data.

    DATA: ls_address TYPE ty_address,
          lt_value   TYPE swdtdd07v.


    CALL FUNCTION 'DDIF_DOMA_GET'
      EXPORTING
        name          = 'MEPROCSTATE'
        langu         = 'E'
      TABLES
        dd07v_tab     = lt_value
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.


****************************CREATE PAYLOAD FROM ABAP*********************
    SORT t_data BY ebeln ebelp.

    LOOP AT t_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      AT NEW ebeln.
        gs_json-id               = <ls_data>-ebeln.
        ASSIGN COMPONENT gs_tvarvc-low OF STRUCTURE <ls_data> TO FIELD-SYMBOL(<lv_value>).
        IF <lv_value> IS ASSIGNED.
          gs_json-po_document_no   = <lv_value>.
        ENDIF.
        gs_json-company_code   = <ls_data>-bukrs.
        gs_json-po_org_no      = <ls_data>-ekorg.
        gs_json-po_grp         = <ls_data>-ekgrp.
        gs_json-vendor_erp_id  = |{ <ls_data>-lifnr ALPHA = OUT }|.
        gs_json-payment_terms  = <ls_data>-zterm.
        gs_json-currency_key   = <ls_data>-waers.
        gs_json-create_ts      = CONV char10( timestamp( iv_date = <ls_data>-aedat iv_time = <ls_data>-ctime ) ).

        CONDENSE gs_json-vendor_erp_id NO-GAPS.
        gs_json-title            = 'Purchase Order'.
        TRY.
            gs_json-status       = lt_value[ domvalue_l = <ls_data>-procstat ]-ddtext.
          CATCH cx_root INTO DATA(lo_data).
        ENDTRY.
        TRY.
            DATA(ls_cdhdr)           = t_cdhdr[ objectid = CONV #( <ls_data>-ebeln ) ].

            IF ls_cdhdr-change_ind <> 'I'.
              gs_json-update_ts      = CONV char10( timestamp( iv_date = ls_cdhdr-udate iv_time = ls_cdhdr-utime ) ).
            ENDIF.
          CATCH cx_root INTO DATA(lo_root).
        ENDTRY.

        TRY.
            DATA(ls_adrc) = t_adrc[ addrnumber = <ls_data>-adrnr ].

            ls_address-address_line1 = ls_adrc-house_num1.
            ls_address-address_line2 = ls_adrc-street.
            ls_address-city          = ls_adrc-city1.
            ls_address-state         = ls_adrc-region.
            ls_address-country       = ls_adrc-country.
            ls_address-zip           = ls_adrc-post_code1.
            gs_json-address          = ls_address.
          CATCH cx_root INTO lo_root.
        ENDTRY.

        IF <ls_data>-loekz = 'X'.
          gs_json-is_deleted       = 'X'.
        ENDIF.
      ENDAT.

      APPEND INITIAL LINE TO gs_json-items ASSIGNING FIELD-SYMBOL(<ls_item>).
      <ls_item>-item_no           = <ls_data>-ebelp.
      <ls_item>-material_no       = condense( |{ <ls_data>-matnr ALPHA = OUT }| ).
      <ls_item>-material_desc     = <ls_data>-txz01.
      <ls_item>-plant             = <ls_data>-werks.
      <ls_item>-storage_location  = <ls_data>-lgort.
      <ls_item>-quantity          = <ls_data>-menge.
      <ls_item>-unit              = <ls_data>-meins.
      <ls_item>-price_unit        = <ls_data>-bprme.
      <ls_item>-unit_nume         = <ls_data>-bpumz.
      <ls_item>-unit_deno         = <ls_data>-bpumn.
      <ls_item>-net_price         = <ls_data>-netwr.
      <ls_item>-tax_code          = <ls_data>-mwskz.

      TRY.
          DATA(lt_eket) = VALUE gs_del_sch( FOR ls_eket IN t_eket
          WHERE ( ebeln = <ls_data>-ebeln AND ebelp = <ls_data>-ebelp )
           (
             quantity = ls_eket-menge
             due_date = CONV char10( timestamp( iv_date = ls_eket-eindt iv_time = ls_eket-uzeit ) )
               )
                ).
          <ls_item>-delivery_schedule = lt_eket.

        CATCH cx_root INTO lo_root.
      ENDTRY.

      <ls_item>-discount = 0.
      <ls_item>-tax      = 0.

      IF <ls_data>-loekz1 IS NOT INITIAL.
        IF <ls_data>-loekz1 EQ 'S'.
          <ls_item>-status   = 'B'.
        ELSEIF <ls_data>-loekz1 EQ 'L'.
          <ls_item>-status   = 'D'.
        ENDIF.
      ENDIF.

      <ls_item>-confirmation_key    = <ls_data>-bstae.
      <ls_item>-del_completed_ind   = <ls_data>-elikz.
      <ls_item>-final_invoice_ind   = <ls_data>-erekz.
      <ls_item>-delivered_qty       = VALUE #( t_poqty[ ebeln = <ls_data>-ebeln ebelp = <ls_data>-ebelp ]-grqty  DEFAULT 0 ).
      <ls_item>-still_del_qty       = VALUE #( t_poqty[ ebeln = <ls_data>-ebeln ebelp = <ls_data>-ebelp ]-pgrqty DEFAULT 0 ).
      <ls_item>-invoiced_qty        = VALUE #( t_poqty[ ebeln = <ls_data>-ebeln ebelp = <ls_data>-ebelp ]-inqty  DEFAULT 0 ).
      <ls_item>-invoiced_value      = VALUE #( t_poqty[ ebeln = <ls_data>-ebeln ebelp = <ls_data>-ebelp ]-inamt  DEFAULT 0 ).
*       data(lv_inv_val) = VALUE #( t_poqty[ ebeln = <ls_data>-ebeln ebelp = <ls_data>-ebelp ]-inamt  DEFAULT 0 ).
*      if lv_inv_val NE 0 and <ls_item>-unit_nume NE 0.
*      <ls_item>-invoiced_value      = lv_inv_val / <ls_item>-unit_nume  .
*      endif.
      <ls_item>-still_invoice_qty   = VALUE #( t_poqty[ ebeln = <ls_data>-ebeln ebelp = <ls_data>-ebelp ]-pinqty DEFAULT 0 ).
      <ls_item>-still_invoice_value = VALUE #( t_poqty[ ebeln = <ls_data>-ebeln ebelp = <ls_data>-ebelp ]-pinamt DEFAULT 0 ).
*      data(lv_still_inv) = VALUE #( t_poqty[ ebeln = <ls_data>-ebeln ebelp = <ls_data>-ebelp ]-pinamt DEFAULT 0 ).
*      if lv_still_inv NE 0 and <ls_item>-unit_nume  NE 0.
*      <ls_item>-still_invoice_value = lv_still_inv / <ls_item>-unit_nume  .
*      endif.

      IF <ls_item>-invoiced_qty        = 0 AND
         <ls_item>-invoiced_value      = 0 AND
         <ls_item>-still_invoice_qty   = 0 AND
         <ls_item>-still_invoice_value = 0.
        <ls_item>-still_invoice_qty   = <ls_item>-quantity.
        <ls_item>-still_invoice_value = <ls_item>-net_price.
      ENDIF.

      IF <ls_data>-loekz1 NE 'L'.
        gs_json-total_cost = gs_json-total_cost + <ls_item>-net_price.
      ENDIF.
      AT END OF ebeln.
        WRITE:/ 'FOR DEVELOPMENT'.
        me->api_call( iv_dest = 'SKYSCEND_TEST' iv_key = 'EerPgzGtqy7sC8KECVYiP52jXV8uf4Jn91T7c7So'
                      iv_buyer = '5fb7fbbc46e0fb00060c56ec').

        WRITE:/ 'FOR QUALITY'.
        me->api_call( iv_dest = 'SKYSCEND_QTY' iv_key = 'beNBG3gwCW8udqp6HPQxP6fhsqvhY0Z57xwtEs8u'
                      iv_buyer = '5fff29d2601e520683c33569').

        WRITE:/ 'FOR STAGE'.
        me->api_call( iv_dest = 'SKYSCEND_STAGE' iv_key = 'ZmpSaktYoU8ofLpaqOIVV4H3LB3uIJiqNIydeHqf'
                      iv_buyer = '605bacef6247b88b7f367278').

        WRITE:/ 'FOR PRODUCTION'.
        me->api_call( iv_dest = 'SKYSCEND_PROD1' iv_key   = 'UznmzUEBo672GPmEF9oVC2hnz11LE8Ug5BnYFUaw'
                      iv_buyer = '6009bf877e4576bd3b7799f6').
        CLEAR gs_json.
      ENDAT.
    ENDLOOP.
  ENDMETHOD.

  METHOD api_call.

    DATA: lo_http_client TYPE REF TO if_http_client,
          lo_rest_client TYPE REF TO cl_rest_http_client,
          lv_url         TYPE        string,
          http_status    TYPE        string,
          lv_body        TYPE        string.

    DATA lr_json_serializer   TYPE REF TO cl_trex_json_serializer.

    DATA: lo_json        TYPE REF TO cl_clb_parse_json,
          lo_response    TYPE REF TO if_rest_entity,
          lo_request     TYPE REF TO if_rest_entity,
          lo_sql         TYPE REF TO cx_sy_open_sql_db,
          status         TYPE  string,
          reason         TYPE  string,
          response       TYPE  string,
          content_length TYPE  string,
          location       TYPE  string,
          content_type   TYPE  string,
          lv_status      TYPE  i.

**************************Ist Call**************************************

    cl_http_client=>create_by_destination(
     EXPORTING
       destination              = iv_dest
     IMPORTING
       client                   = lo_http_client
     EXCEPTIONS
       argument_not_found       = 1
       destination_not_found    = 2
       destination_no_authority = 3
       plugin_not_active        = 4
       internal_error           = 5
       OTHERS                   = 6
    ).

    lo_http_client->propertytype_logon_popup = lo_http_client->co_disabled.

    CREATE OBJECT lo_rest_client
      EXPORTING
        io_http_client = lo_http_client.
*   lo_http_client->request->set_version( if_http_request=>co_protocol_version_1_0 ).

    IF lo_http_client IS BOUND AND lo_rest_client IS BOUND.

      CONCATENATE '/ext/s4/' iv_buyer '/po' INTO lv_url.
*      lv_url = '/ext/s4/5fb7fbbc46e0fb00060c56ec/po'.

      cl_http_utility=>set_request_uri(
        EXPORTING
          request = lo_http_client->request    " HTTP Framework (iHTTP) HTTP Request
          uri     = lv_url                     " URI String (in the Form of /path?query-string)
      ).

* serialize data into JSON and converting ABAP field names into camelCase
      lv_body = /ui2/cl_json=>serialize( data = gs_json pretty_name = /ui2/cl_json=>pretty_mode-camel_case conversion_exits = abap_true ).

* Set Payload or body ( JSON or XML)
      lo_request = lo_rest_client->if_rest_client~create_request_entity( ).
      lo_request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_json ).
*      lo_request->set_content_compression( abap_true ).
      lo_request->set_string_data( lv_body ).

      cl_demo_output=>write_json( lv_body ).
      cl_demo_output=>display( ).

      CALL METHOD lo_rest_client->if_rest_client~set_request_header
        EXPORTING
          iv_name  = 'x-api-key'
          iv_value = iv_key. "Set your header .

* POST
      lo_rest_client->if_rest_resource~post( lo_request ).

* Collect response
      lo_response = lo_rest_client->if_rest_client~get_response_entity( ).
      http_status = lv_status = lo_response->get_header_field( '~status_code' ).
      reason = lo_response->get_header_field( '~status_reason' ).
      content_length = lo_response->get_header_field( 'content-length' ).
      location = lo_response->get_header_field( 'location' ).
      content_type = lo_response->get_header_field( 'content-type' ).
      response = lo_response->get_string_data( ).

      WRITE: http_status.
      WRITE: reason.
      WRITE: response.
    ENDIF.
    CLEAR : lv_url.
  ENDMETHOD.
ENDCLASS.
