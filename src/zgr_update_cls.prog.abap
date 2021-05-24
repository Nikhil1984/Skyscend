*&---------------------------------------------------------------------*
*& Include          ZGR_UPDATE_CLS
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION.

  PUBLIC SECTION.

    METHODS : get_data,api_call.

*Convert ABAP to JSON
    TYPES:BEGIN OF ty_items,
            receipt_item_no  TYPE string,
            po_id            TYPE string,
            po_line_item_no  TYPE string,
            material_no      TYPE string,
            material_desc    TYPE string,
            serial_no        TYPE string,
            plant            TYPE string,
            storage_location TYPE string,
            base_unit        TYPE string,
            base_quantity    TYPE i,
            entry_unit       TYPE string,
            entry_quantity   TYPE i,
            movement_type    TYPE i,
          END OF ty_items,

          BEGIN OF ty_ekpo,
            ebeln TYPE ekpo-ebeln,
            ebelp TYPE ekpo-ebelp,
            txz01 TYPE ekpo-txz01,
          END OF ty_ekpo.

    TYPES: BEGIN OF ty_json_req,
             id             TYPE string,
             delivery_note  TYPE string,
             bill_of_lading TYPE string,
             vendor_erp_id  TYPE string,
             ts             TYPE string,
             items          TYPE STANDARD TABLE OF ty_items WITH EMPTY KEY,
           END OF ty_json_req.

    DATA: gs_json_req TYPE ty_json_req,
          gs_items    TYPE ty_items,
          gt_ekpo     TYPE TABLE OF ty_ekpo.

ENDCLASS.

CLASS lcl_class IMPLEMENTATION.

  METHOD get_data.

*Get details of GR
    SELECT   mblnr ,
       mjahr ,
       vgart ,
       blart ,
       bldat ,
       budat ,
       cpudt ,
       cputm ,
       tcode ,
       zeile ,
       bwart ,
       lifnr ,
      charg,
       matnr ,
       werks ,
       lgort ,
       dmbtr ,
       shkum ,
       menge ,
       meins ,
       erfme ,
       erfmg ,
       ebeln ,
       ebelp ,
       frbnr ,
       xblnr ,
       sgtxt
      INTO TABLE @gt_data
      FROM matdoc
      WHERE mblnr IN @s_mblnr
      AND cpudt IN @s_date
      AND cputm IN @s_time
      AND ( vgart = 'WE' AND blart = 'WE' ).

    IF sy-subrc = 0.

      DELETE gt_data WHERE ebeln IS INITIAL.

      SELECT ebeln, ebelp, txz01 FROM ekpo INTO TABLE @gt_ekpo
      FOR ALL ENTRIES IN @gt_data WHERE
      ebeln = @gt_data-ebeln AND ebelp = @gt_data-ebelp.

    ENDIF.

  ENDMETHOD.

  METHOD api_call.

    DATA: lo_http_client TYPE REF TO if_http_client,
          lo_rest_client TYPE REF TO cl_rest_http_client,
          lo_request     TYPE REF TO if_rest_entity,
          lo_response    TYPE REF TO if_rest_entity,
          lv_url         TYPE  string,
          http_status    TYPE  string,
          lv_body        TYPE  string,
          status         TYPE  string,
          reason         TYPE  string,
          response       TYPE  string,
          content_length TYPE  string,
          location       TYPE  string,
          content_type   TYPE  string,
          lv_status      TYPE  i.

****************************CREATE PAYLOAD FROM ABAP*********************
    SORT gt_data BY mblnr zeile.

    LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      AT NEW mblnr.
        gs_json_req-id              = <ls_data>-mjahr && |-| && <ls_data>-mblnr.
        gs_json_req-delivery_note   = <ls_data>-xblnr.
        gs_json_req-bill_of_lading   = <ls_data>-frbnr.
        gs_json_req-vendor_erp_id    = |{ <ls_data>-lifnr ALPHA = OUT }|.
        CONDENSE gs_json_req-vendor_erp_id.

        TRY.
            cl_pco_utility=>convert_abap_timestamp_to_java( EXPORTING iv_date      = <ls_data>-cpudt
                                                                      iv_time      = <ls_data>-cputm
                                                            IMPORTING ev_timestamp = DATA(lv_tstamp) ).
            IF lv_tstamp IS NOT INITIAL.
              gs_json_req-ts              =  lv_tstamp+0(10).
            ENDIF.
          CATCH cx_root INTO DATA(lo_root).
        ENDTRY.

      ENDAT.

      APPEND INITIAL LINE TO gs_json_req-items ASSIGNING FIELD-SYMBOL(<ls_item>).
      <ls_item>-receipt_item_no   = <ls_data>-zeile.
      <ls_item>-po_id             = |{ <ls_data>-ebeln ALPHA = OUT }|.
      <ls_item>-po_line_item_no   = <ls_data>-ebelp.
      <ls_item>-material_no       = <ls_data>-matnr.

      TRY.
          DATA(ls_text) = gt_ekpo[ ebeln = <ls_data>-ebeln ebelp = <ls_data>-ebelp ].
          <ls_item>-material_desc     = ls_text-txz01.
        CATCH cx_root INTO lo_root.
      ENDTRY.

      <ls_item>-serial_no         = <ls_data>-charg.
      <ls_item>-plant             = <ls_data>-werks.
      <ls_item>-storage_location  = <ls_data>-lgort.
      <ls_item>-base_unit         = <ls_data>-meins.
      <ls_item>-base_quantity     = <ls_data>-menge.
      <ls_item>-entry_unit        = <ls_data>-erfme.
      <ls_item>-entry_quantity    = <ls_data>-erfmg.
      <ls_item>-movement_type     = <ls_data>-bwart.

      AT END OF mblnr.

        cl_http_client=>create_by_destination(
         EXPORTING
           destination              = 'SKYSCEND_TEST'
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

        IF lo_http_client IS BOUND AND lo_rest_client IS BOUND.
          lv_url = '/ext/s4/5fb7fbbc46e0fb00060c56ec/receipt'.

          cl_http_utility=>set_request_uri(
            EXPORTING
              request = lo_http_client->request    " HTTP Framework (iHTTP) HTTP Request
              uri     = lv_url                     " URI String (in the Form of /path?query-string)
          ).

* serialize data into JSON, skipping initial fields and converting ABAP field names into camelCase
          lv_body = /ui2/cl_json=>serialize( data = gs_json_req compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
          WRITE:/ lv_body.

* Set Payload or body ( JSON or XML)
          lo_request = lo_rest_client->if_rest_client~create_request_entity( ).
          lo_request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_json ).
          lo_request->set_content_compression( abap_true ).
          lo_request->set_string_data( lv_body ).

          CALL METHOD lo_rest_client->if_rest_client~set_request_header
            EXPORTING
              iv_name  = 'x-api-key'
              iv_value = 'EerPgzGtqy7sC8KECVYiP52jXV8uf4Jn91T7c7So'. "Set your header .

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
      ENDAT.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
