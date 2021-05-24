*&---------------------------------------------------------------------*
*& Include          ZINV_UPDATE_CLS
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION.

  PUBLIC SECTION.

    METHODS : get_data,
      api_call IMPORTING it_ebeln TYPE range_ebeln_in_t iv_dest  TYPE c
                         iv_key   TYPE string           iv_buyer TYPE string,
      trigger_po,
      process_data.

    DATA : lv_char TYPE char10,
           lt_po   TYPE range_ebeln_in_t.

*Convert ABAP to JSON
    TYPES:BEGIN OF ty_items,
            item_no          TYPE string,
            line_item_no     TYPE string,
            po_id            TYPE string,
            material_no      TYPE string,
            material_desc    TYPE string,
            plant            TYPE string,
            storage_location TYPE string,
            quantity         TYPE ekpo-menge,
            tax              TYPE ekpo-netwr,
            unit             TYPE string,
            delivery_charges TYPE ekpo-netwr,
            net_price        TYPE ekpo-netwr,
          END OF ty_items.

    TYPES: BEGIN OF ty_json_req,
             id                    TYPE string,
             fiscal_year           TYPE string,
             invtyp                TYPE string,
             supplier_invoice_no   TYPE string,
             vendor_erp_id         TYPE string,
             company_code          TYPE string,
             total_payable_amount  TYPE ekpo-netwr,
             discount              TYPE ekpo-netwr,
             currency_key          TYPE string,
             status                TYPE string,
             ts                    TYPE i,
             invoice_due_date      TYPE i,
             reversed              TYPE boolean,
             reversal_document_no  TYPE string,
             reversal_fiscal_year  TYPE string,
             reversal_posting_date TYPE i,
             payment_block         TYPE string,
             items                 TYPE STANDARD TABLE OF ty_items WITH EMPTY KEY,
           END OF ty_json_req,

           BEGIN OF ty_bsik,
             gjahr TYPE bsik-gjahr,
             belnr TYPE bsik-belnr,
             zlspr TYPE bsik-zlspr,
           END OF ty_bsik,

           BEGIN OF ty_t008t,
             spras TYPE t008t-spras,
             zahls TYPE t008t-zahls,
             textl TYPE t008t-textl,
           END OF ty_t008t,

           BEGIN OF ty_rev,
             stblg TYPE stblg,
           END OF ty_rev.

    TYPES: BEGIN OF ty_due,
             belnr TYPE rbkp-belnr,
             gjahr TYPE rbkp-gjahr,
             bukrs TYPE rbkp-bukrs,
             netdt TYPE faede-netdt,
           END OF ty_due.

    DATA: gs_json_req TYPE ty_json_req,
          gs_items    TYPE ty_items,
          gt_due      TYPE TABLE OF ty_due,
          lt_blocked  TYPE TABLE OF ty_bsik,
          lt_t008t    TYPE TABLE OF ty_t008t,
          gt_reversed TYPE TABLE OF ty_data,
          gt_rev_data TYPE TABLE OF ty_data.

ENDCLASS.

CLASS lcl_class IMPLEMENTATION.

  METHOD get_data.

    DATA: lt_objid   TYPE fip_t_order_id_range,
          ls_time    TYPE range_tims,
          lv_jobname TYPE tbtcm-jobname.


    lt_objid = CORRESPONDING #( s_belnr[] ).

    CALL FUNCTION 'GET_JOB_RUNTIME_INFO'
      IMPORTING
        jobname         = lv_jobname
      EXCEPTIONS
        no_runtime_info = 1
        OTHERS          = 2.

    IF lv_jobname CS 'ZINV_UPDATE_REPORT'.

      SELECT SINGLE name, sign, opti, low, high INTO @DATA(gs_from)
          FROM tvarvc
          WHERE name = 'ZINV_FROM_TIME'
          AND type = 'P'.
      IF sy-subrc = 0.
        ls_time-sign = 'I'.
        ls_time-option = 'GT'.
        ls_time-high = ''.
        ls_time-low = gs_from-low.

        MODIFY s_time[] FROM ls_time INDEX 1 TRANSPORTING low.
      ENDIF.

      UPDATE tvarvc SET low = sy-uzeit WHERE name = 'ZINV_FROM_TIME'.

    ENDIF.

**select invoice which were created or changed
    SELECT belnr, gjahr
      INTO TABLE @DATA(t_ekbe)
      FROM ekbe
     WHERE cpudt      IN @s_date
       AND cputm      IN @s_time
       AND belnr      IN @s_belnr
        AND ( vgabe EQ 2 OR vgabe EQ 3 ).
    IF sy-subrc = 0.

*Get details of fetched invoice
      SELECT  a~belnr,
              a~gjahr,
              a~budat,
              a~xblnr,
              a~lifnr,
              a~bukrs,
              a~rmwwr,
              a~wskto,
              a~waers,
              a~rbstat,
              a~xrech,
              a~stblg,
              a~stjah,
              a~cpudt,
              a~cputm,
              a~vgart,
              a~zlspr,
              a~wmwst1,
              b~buzei,
              b~ebeln,
              b~ebelp,
              b~matnr,
              b~menge,
              b~mwskz,
              b~werks,
              b~bstme,
              b~bnkan,
              b~wrbtr,
              c~txz01,
              c~lgort
        INTO TABLE @gt_data
        FROM rbkp AS a
        JOIN rseg AS b
        ON a~belnr = b~belnr
        JOIN ekpo AS c
        ON b~ebeln = c~ebeln
        AND b~ebelp = c~ebelp
       FOR ALL ENTRIES IN @t_ekbe
       WHERE a~belnr EQ @t_ekbe-belnr
         AND a~gjahr EQ @t_ekbe-gjahr.

      IF sy-subrc = 0.

        gt_reversed = VALUE #( FOR wa_data IN gt_data
        WHERE ( vgart = 'RS' ) ( wa_data ) ).

        IF gt_reversed IS NOT INITIAL.

          SELECT  a~belnr,
              a~gjahr,
              a~budat,
              a~xblnr,
              a~lifnr,
              a~bukrs,
              a~rmwwr,
              a~wskto,
              a~waers,
              a~rbstat,
              a~xrech,
              a~stblg,
              a~stjah,
              a~cpudt,
              a~cputm,
              a~vgart,
              a~zlspr,
              a~wmwst1,
              b~buzei,
              b~ebeln,
              b~ebelp,
              b~matnr,
              b~menge,
              b~mwskz,
              b~werks,
              b~bstme,
              b~bnkan,
              b~wrbtr,
              c~txz01,
              c~lgort
        INTO TABLE @gt_rev_data
        FROM rbkp AS a
        JOIN rseg AS b
        ON a~belnr = b~belnr
        JOIN ekpo AS c
        ON b~ebeln = c~ebeln
        AND b~ebelp = c~ebelp
       FOR ALL ENTRIES IN @gt_reversed
       WHERE a~bukrs EQ @gt_reversed-bukrs
         AND a~stblg EQ @gt_reversed-belnr
         AND a~stjah EQ @gt_reversed-gjahr.
          IF sy-subrc = 0.
            DELETE ADJACENT DUPLICATES FROM gt_rev_data COMPARING belnr gjahr buzei.
            APPEND LINES OF gt_rev_data TO gt_data.
          ENDIF.

          DELETE gt_data WHERE vgart = 'RS'.
        ENDIF.

        SELECT supplierinvoice,
               fiscalyear,
               companycode,
               netduedate
          INTO TABLE @gt_due
          FROM c_supplierinvoicediscountdates "csupinvdisd
           FOR ALL ENTRIES IN @gt_data
         WHERE supplierinvoice = @gt_data-belnr
           AND fiscalyear      = @gt_data-gjahr
           AND companycode     = @gt_data-bukrs.

        SELECT gjahr,belnr,zlspr FROM bsik INTO TABLE @DATA(lt_bsik)
         FOR ALL ENTRIES IN @gt_data WHERE belnr = @gt_data-belnr
         AND zlspr NE ' '.
        IF sy-subrc = 0.
          APPEND LINES OF lt_bsik TO lt_blocked.
        ENDIF.

        SELECT gjahr,belnr,zlspr FROM bsak INTO TABLE @DATA(lt_bsak)
         FOR ALL ENTRIES IN @gt_data WHERE belnr = @gt_data-belnr
         AND zlspr NE ' '.
        IF sy-subrc = 0.
          APPEND LINES OF lt_bsak TO lt_blocked.
        ENDIF.

        DELETE ADJACENT DUPLICATES FROM lt_blocked COMPARING belnr gjahr.

        IF lt_blocked IS NOT INITIAL.

          SELECT spras, zahls, textl FROM t008t INTO TABLE @lt_t008t
          FOR ALL ENTRIES IN @lt_blocked WHERE zahls = @lt_blocked-zlspr
          AND spras = @sy-langu.

        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD process_data.
    DATA: lt_dd07v TYPE TABLE OF dd07v,
          lt_po    TYPE range_ebeln_in_t.

**********************GET INVOICE STATUS TEXT****************************

    CALL FUNCTION 'DD_DOMVALUES_GET'
      EXPORTING
        domname        = 'RBSTAT'
        text           = 'X'
        langu          = sy-langu
      TABLES
        dd07v_tab      = lt_dd07v
      EXCEPTIONS
        wrong_textflag = 1
        OTHERS         = 2.

****************************CREATE PAYLOAD FROM ABAP*********************
    SORT gt_data BY belnr buzei.

    LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      AT NEW belnr.
        gs_json_req-id               = <ls_data>-belnr.
        gs_json_req-fiscal_year      = <ls_data>-gjahr.
        gs_json_req-invtyp           = 'P'.
        gs_json_req-supplier_invoice_no = <ls_data>-xblnr.
        gs_json_req-vendor_erp_id    = |{ <ls_data>-lifnr ALPHA = OUT }|.
        CONDENSE gs_json_req-vendor_erp_id.
        gs_json_req-company_code     = <ls_data>-bukrs.
        gs_json_req-total_payable_amount = <ls_data>-rmwwr.
        gs_json_req-discount         = <ls_data>-wskto.
        gs_json_req-currency_key     = <ls_data>-waers.

        READ TABLE lt_dd07v ASSIGNING FIELD-SYMBOL(<ls_dd07>) WITH KEY valpos = <ls_data>-rbstat.
        IF sy-subrc = 0.
          gs_json_req-status           = <ls_dd07>-ddtext.
        ENDIF.

        TRY.
            cl_pco_utility=>convert_abap_timestamp_to_java( EXPORTING iv_date      = <ls_data>-cpudt
                                                                      iv_time      = <ls_data>-cputm
                                                            IMPORTING ev_timestamp = DATA(lv_tstamp) ).
            IF lv_tstamp IS NOT INITIAL.
              gs_json_req-ts              = CONV #( lv_tstamp+0(10) ).
            ENDIF.
          CATCH cx_root INTO DATA(lo_root).
        ENDTRY.
        TRY.
            CLEAR lv_tstamp.
            cl_pco_utility=>convert_abap_timestamp_to_java( EXPORTING iv_date      = VALUE #( gt_due[ belnr = <ls_data>-belnr
                                                                                                      gjahr = <ls_data>-gjahr
                                                                                                      bukrs = <ls_data>-bukrs ]-netdt OPTIONAL )
                                                                      iv_time      = '000000'
                                                            IMPORTING ev_timestamp = lv_tstamp ).

            gs_json_req-invoice_due_date   = CONV #( lv_tstamp+0(10) ).
          CATCH cx_root INTO lo_root.
        ENDTRY.

**Passing Reversal Document Details
        IF <ls_data>-stblg IS NOT INITIAL.
          gs_json_req-reversed              = abap_true.
          gs_json_req-reversal_document_no  = <ls_data>-stblg.
          gs_json_req-reversal_fiscal_year  = <ls_data>-stjah.
          TRY.
              CLEAR lv_tstamp.
              cl_pco_utility=>convert_abap_timestamp_to_java( EXPORTING iv_date      = VALUE #( gt_reversed[ belnr = <ls_data>-stblg
                                                                                                             gjahr = <ls_data>-stjah
                                                                                                             bukrs = <ls_data>-bukrs ]-budat OPTIONAL )
                                                                        iv_time      = '000000'
                                                              IMPORTING ev_timestamp = lv_tstamp ).

              gs_json_req-reversal_posting_date  = CONV #( lv_tstamp+0(10) ).
            CATCH cx_root INTO lo_root.
          ENDTRY.
        ENDIF.

        READ TABLE lt_blocked ASSIGNING FIELD-SYMBOL(<ls_bsik>) WITH KEY belnr = <ls_data>-belnr.
        IF <ls_bsik> IS ASSIGNED.

          READ TABLE lt_t008t ASSIGNING FIELD-SYMBOL(<ls_t008t>) WITH KEY zahls = <ls_bsik>-zlspr.
          IF <ls_t008t> IS ASSIGNED.
            gs_json_req-payment_block = <ls_t008t>-textl.
          ENDIF.
        ENDIF.

      ENDAT.
      APPEND INITIAL LINE TO gs_json_req-items ASSIGNING FIELD-SYMBOL(<ls_item>).
      <ls_item>-item_no           = <ls_data>-buzei.
      <ls_item>-line_item_no      = <ls_data>-ebelp.
      <ls_item>-po_id             = |{ <ls_data>-ebeln ALPHA = OUT }|.
      <ls_item>-material_no       = condense( |{ <ls_data>-matnr ALPHA = OUT }| ).
      <ls_item>-material_desc     = <ls_data>-txz01.
      <ls_item>-plant             = <ls_data>-werks.
      <ls_item>-storage_location  = <ls_data>-lgort.
      <ls_item>-quantity          = <ls_data>-menge.
      <ls_item>-tax               = <ls_data>-wmwst1.
*      <ls_item>-tax               = 0.
      <ls_item>-unit              = <ls_data>-bstme.
      <ls_item>-delivery_charges  = <ls_data>-bnkan.
      <ls_item>-net_price         = <ls_data>-wrbtr.

      lt_po = VALUE range_ebeln_in_t( BASE CORRESPONDING #( lt_po ) ( sign   = 'I'
                                                                      option = 'EQ'
                                                                      low    = <ls_data>-ebeln ) ).

      AT END OF belnr.
        WRITE:/ 'FOR DEVELOPMENT'.
        me->api_call( it_ebeln = lt_po iv_dest = 'SKYSCEND_TEST'
                      iv_key   = 'EerPgzGtqy7sC8KECVYiP52jXV8uf4Jn91T7c7So'
                      iv_buyer = '5fb7fbbc46e0fb00060c56ec').
        WRITE:/ 'FOR QUALITY'.
        me->api_call( it_ebeln = lt_po iv_dest = 'SKYSCEND_QTY'
                      iv_key   = 'beNBG3gwCW8udqp6HPQxP6fhsqvhY0Z57xwtEs8u'
                      iv_buyer = '5fff29d2601e520683c33569').
        WRITE:/ 'FOR STAGE'.
        me->api_call( it_ebeln = lt_po iv_dest = 'SKYSCEND_STAGE'
                      iv_key   = 'ZmpSaktYoU8ofLpaqOIVV4H3LB3uIJiqNIydeHqf'
                      iv_buyer = '605bacef6247b88b7f367278').
         WRITE:/ 'FOR PRODUCTION'.
        me->api_call( it_ebeln = lt_po iv_dest = 'SKYSCEND_PROD1'
                      iv_key   = 'UznmzUEBo672GPmEF9oVC2hnz11LE8Ug5BnYFUaw'
                      iv_buyer = '6009bf877e4576bd3b7799f6').
        CLEAR lt_po.
      ENDAT.
    ENDLOOP.
    IF sy-subrc = 0.
      SORT me->lt_po.
      DELETE ADJACENT DUPLICATES FROM me->lt_po.
      IF me->lt_po IS NOT INITIAL.
        trigger_po( ).
      ENDIF.
    ENDIF.
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

****************************************Ist Call**************************************

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

      CONCATENATE '/ext/s4/' iv_buyer '/invoice' INTO lv_url.
*      lv_url = '/ext/s4/5fb7fbbc46e0fb00060c56ec/invoice'.

      cl_http_utility=>set_request_uri(
        EXPORTING
          request = lo_http_client->request    " HTTP Framework (iHTTP) HTTP Request
          uri     = lv_url                     " URI String (in the Form of /path?query-string)
      ).

* serialize data into JSON, skipping initial fields and converting ABAP field names into camelCase
      lv_body = /ui2/cl_json=>serialize( data = gs_json_req compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
*      WRITE:/ lv_body.
      cl_demo_output=>write_json( lv_body ).
      cl_demo_output=>display( ).

* Set Payload or body ( JSON or XML)
      lo_request = lo_rest_client->if_rest_client~create_request_entity( ).
      lo_request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_json ).
      lo_request->set_content_compression( abap_true ).
      lo_request->set_string_data( lv_body ).

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

      IF lv_status = 200.
        APPEND LINES OF it_ebeln TO lt_po.
      ENDIF.

      WRITE: http_status.
      WRITE: reason.
      WRITE: response.
    ENDIF.
  ENDMETHOD.
  METHOD trigger_po.
    DATA: lv_name   TYPE tbtcjob-jobname,
          lv_jcount TYPE tbtcjob-jobcount.

    lv_name = |PO_Invoice{ sy-datum }{ sy-uzeit }|.
    CALL FUNCTION 'JOB_OPEN'
      EXPORTING
        jobname          = lv_name
      IMPORTING
        jobcount         = lv_jcount
      EXCEPTIONS
        cant_create_job  = 1
        invalid_job_data = 2
        jobname_missing  = 3
        OTHERS           = 4.
    IF sy-subrc = 0.
      SUBMIT zpo_update_report AND RETURN
         VIA JOB lv_name NUMBER lv_jcount
        WITH s_ebeln IN me->lt_po[].
      IF sy-subrc = 0.
        CALL FUNCTION 'JOB_CLOSE'
          EXPORTING
            jobcount             = lv_jcount
            jobname              = lv_name
            strtimmed            = abap_true
          EXCEPTIONS
            cant_start_immediate = 1
            invalid_startdate    = 2
            jobname_missing      = 3
            job_close_failed     = 4
            job_nosteps          = 5
            job_notex            = 6
            lock_failed          = 7
            invalid_target       = 8
            invalid_time_zone    = 9
            OTHERS               = 10.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.
      ENDIF.
    ENDIF.
    CLEAR me->lt_po[].
  ENDMETHOD.
ENDCLASS.
