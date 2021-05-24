*&---------------------------------------------------------------------*
*& Include          ZINV_UPDATE_CLS
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION.

  PUBLIC SECTION.

    METHODS : get_data,
      api_call IMPORTING iv_dest TYPE c iv_key TYPE string iv_buyer TYPE string.

*Convert ABAP to JSON
    TYPES:BEGIN OF ty_address,
            address_line1 TYPE string,
            address_line2 TYPE string,
            city          TYPE string,
            state         TYPE string,
            country       TYPE string,
            zip           TYPE string,
          END OF ty_address,

          BEGIN OF ty_porg,
            org_no           TYPE strng,
            invoice_party_id TYPE string,
          END OF ty_porg,

          BEGIN OF ty_comp,
            company_code  TYPE string,
            payment_terms TYPE string,
            is_deleted    TYPE boolean,
          END OF ty_comp,

          BEGIN OF ty_ws_req_body,
            vendor_id              TYPE string,
            name                   TYPE string,
            email_id               TYPE string,
            ph_num                 TYPE string,
            ph_country_code        TYPE sktelfto,
            supplier_creation_date TYPE string,
            tax_id                 TYPE string,
            address                TYPE ty_address,
            is_deleted             TYPE boolean,
            purchase_orginzations  TYPE STANDARD TABLE OF ty_porg WITH EMPTY KEY,
            supplier_company       TYPE STANDARD TABLE OF ty_comp WITH EMPTY KEY,
          END OF ty_ws_req_body.

    DATA: ws_req_body TYPE ty_ws_req_body,
          ws_addr     TYPE ty_address,
          it_comp     TYPE TABLE OF ty_comp,
          it_porg     TYPE TABLE OF ty_porg.

ENDCLASS.

CLASS lcl_class IMPLEMENTATION.

  METHOD get_data.

    DATA: lt_objid     TYPE fip_t_order_id_range,
          lv_char      TYPE char10,
          lv_timestamp TYPE string,
          ls_time      TYPE range_tims,
          lv_jobname   TYPE tbtcm-jobname.

    IF sy-batch = abap_true AND
       s_time IS INITIAL.
      SELECT SINGLE name, sign, opti, low, high INTO @DATA(gs_from)
          FROM tvarvc
          WHERE name = 'ZSUPPLIER_FROM'
          AND type = 'P'.
      IF sy-subrc = 0.
        ls_time-sign = 'I'.
        ls_time-option = 'GT'.
        ls_time-high = ''.
        ls_time-low = gs_from-low.

        MODIFY s_time[] FROM ls_time INDEX 1 TRANSPORTING low.
      ENDIF.
      UPDATE tvarvc SET low = sy-uzeit WHERE name = 'ZSUPPLIER_FROM'.
    ENDIF.

    SELECT objectclas ,objectid ,changenr ,username ,udate ,utime ,tcode
      FROM cdhdr
      INTO TABLE @DATA(it_cdhdr1)
     WHERE ( objectclas = 'ADRESSE'                                             "Added for ADDRESS CHANGES
       AND udate IN @s_date
       AND utime IN @s_time
       AND tcode EQ 'BP'
       AND change_ind = 'U' ).
    IF sy-subrc  = 0.
      SELECT lifnr ,land1,name1,name2,ort01,ort02,pstl2,regio,stras,adrnr,erdat,loevm
        FROM lfa1
        INTO TABLE @DATA(it_lfa11)
         FOR ALL ENTRIES IN @it_cdhdr1
       WHERE lifnr IN @s_lifnr
         AND adrnr =  @it_cdhdr1-objectid+4(10).
    ENDIF.

    lt_objid = CORRESPONDING #( s_lifnr[] ).

    SELECT objectclas ,objectid ,changenr ,username ,udate ,utime ,tcode FROM cdhdr
     INTO TABLE @DATA(it_cdhdr)
     WHERE ( objectclas = 'KRED'
     AND udate IN @s_date
     AND utime IN @s_time
     AND objectid IN @lt_objid ).

    IF sy-subrc = 0.

      SELECT objectclas, objectid, changenr, tabname, tabkey, fname, chngind, value_new, value_old FROM cdpos
      INTO TABLE @DATA(it_cdpos)
      FOR ALL ENTRIES IN @it_cdhdr
      WHERE changenr = @it_cdhdr-changenr.

      SELECT lifnr ,land1,name1,name2,ort01,ort02,pstl2,regio,stras,adrnr,erdat,loevm FROM
        lfa1 INTO TABLE @DATA(it_lfa1)
        FOR ALL ENTRIES IN @it_cdhdr
        WHERE lifnr = @it_cdhdr-objectid+0(10).
      IF sy-subrc = 0.
*
        APPEND LINES OF it_lfa11 TO it_lfa1.                                              "ADDED FOR ADDRESS CHANGES
        SORT it_lfa1 BY lifnr.
        DELETE ADJACENT DUPLICATES FROM it_lfa1 COMPARING lifnr.

        SELECT  partner, taxnum FROM dfkkbptaxnum INTO TABLE @DATA(it_gstin)
                  FOR ALL ENTRIES IN @it_lfa1
                  WHERE partner = @it_lfa1-lifnr.

        SELECT addrnumber,house_num1,street,city1,post_code1,country,region FROM adrc INTO TABLE @DATA(it_adrc)
           FOR ALL ENTRIES IN @it_lfa1 WHERE addrnumber = @it_lfa1-adrnr.

        SELECT addrnumber,smtp_addr FROM adr6 INTO TABLE @DATA(it_adr6) FOR ALL ENTRIES IN
         @it_lfa1 WHERE addrnumber = @it_lfa1-adrnr.

        SELECT addrnumber, country, tel_number FROM adr2 INTO TABLE @DATA(it_adr2) FOR ALL ENTRIES IN
        @it_lfa1 WHERE addrnumber = @it_lfa1-adrnr.

        SELECT land1,
               telefto
          INTO TABLE @DATA(it_t005k)
          FROM t005k
           FOR ALL ENTRIES IN @it_adr2
         WHERE land1 = @it_adr2-country.

        SELECT lifnr,
               bukrs,
               loevm,
               zterm
          INTO TABLE @DATA(it_lfb1)
          FROM lfb1
           FOR ALL ENTRIES IN @it_lfa1
         WHERE lifnr = @it_lfa1-lifnr.

        SELECT lifnr,
               ekorg
          INTO TABLE @DATA(it_lfm1)
          FROM lfm1
            FOR ALL ENTRIES IN @it_lfa1
         WHERE lifnr = @it_lfa1-lifnr.

        SELECT lifnr,ekorg,lifn2 FROM wyt3 INTO TABLE @DATA(it_wyt3) FOR ALL ENTRIES IN
        @it_lfm1 WHERE lifnr = @it_lfm1-lifnr
                   AND ekorg = @it_lfm1-ekorg
                   AND parvw = 'RS' .

      ENDIF.
    ENDIF.


    SORT it_cdhdr BY changenr DESCENDING.
    LOOP AT it_lfa1 ASSIGNING FIELD-SYMBOL(<fs_lfa1>).
      READ TABLE it_cdhdr ASSIGNING FIELD-SYMBOL(<fs_cdhdr>) WITH KEY objectid = <fs_lfa1>-lifnr.
      IF sy-subrc = 0.
        TRY.
            CALL METHOD cl_pco_utility=>convert_abap_timestamp_to_java
              EXPORTING
                iv_date      = <fs_cdhdr>-udate
                iv_time      = <fs_cdhdr>-utime
              IMPORTING
                ev_timestamp = lv_timestamp.
          CATCH cx_root INTO DATA(lo_root).
        ENDTRY.

        ws_req_body-supplier_creation_date = lv_timestamp+0(10).

      ENDIF.

      ws_req_body-is_deleted             = <fs_lfa1>-loevm.

      READ TABLE it_adrc ASSIGNING FIELD-SYMBOL(<fs_adrc>) WITH KEY addrnumber = <fs_lfa1>-adrnr.
      IF sy-subrc = 0.
        ws_addr-address_line1 = <fs_adrc>-house_num1.
        ws_addr-address_line2 = <fs_adrc>-street.
        ws_addr-city          = <fs_adrc>-city1.
        ws_addr-state         = <fs_adrc>-region.
        ws_addr-country       = <fs_adrc>-country.
        ws_addr-zip           = <fs_adrc>-post_code1.
      ENDIF.

      ws_req_body-vendor_id = |{ <fs_lfa1>-lifnr ALPHA = OUT }|.
      CONDENSE ws_req_body-vendor_id.

      ws_req_body-name = <fs_lfa1>-name1.

      READ TABLE it_adr6 ASSIGNING FIELD-SYMBOL(<fs_adr6>) WITH KEY addrnumber = <fs_lfa1>-adrnr.
      IF sy-subrc = 0.
        ws_req_body-email_id = <fs_adr6>-smtp_addr.
      ENDIF.

      READ TABLE it_adr2  ASSIGNING FIELD-SYMBOL(<fs_adr2>) WITH KEY addrnumber = <fs_lfa1>-adrnr.
      IF sy-subrc = 0.
        ws_req_body-ph_num = <fs_adr2>-tel_number.
        ws_req_body-ph_country_code = VALUE #( it_t005k[ land1 = <fs_adr2>-country ]-telefto DEFAULT space ).
      ENDIF.


      READ TABLE it_gstin ASSIGNING FIELD-SYMBOL(<fs_gstin>) WITH KEY partner = <fs_lfa1>-lifnr.
      IF sy-subrc = 0.
        ws_req_body-tax_id = <fs_gstin>-taxnum.
      ENDIF.

      TRY.
          it_porg = VALUE #( FOR ls_lfm1 IN it_lfm1 WHERE ( lifnr  = <fs_lfa1>-lifnr )
                                                          ( org_no = ls_lfm1-ekorg
                                                            invoice_party_id = VALUE #( it_wyt3[ lifnr = ls_lfm1-lifnr
                                                                                                 ekorg = ls_lfm1-ekorg ]-lifn2 DEFAULT ls_lfm1-lifnr ) ) ).
        CATCH cx_root INTO lo_root.
      ENDTRY.
      TRY.
          it_comp = VALUE #( FOR ls_lfb1 IN it_lfb1 WHERE ( lifnr = <fs_lfa1>-lifnr )
                                                          ( company_code  = ls_lfb1-bukrs
                                                            payment_terms = ls_lfb1-zterm
                                                            is_deleted    = ls_lfb1-loevm ) ).
        CATCH cx_root INTO lo_root.
      ENDTRY.
      ws_req_body-purchase_orginzations = it_porg.
      ws_req_body-supplier_company      = it_comp.
*      ws_req_body-registration_status   = 'REGISTERED'.
      ws_req_body-address = ws_addr.

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
        me->api_call( iv_dest = 'SKYSCEND_PROD1' iv_key = 'UznmzUEBo672GPmEF9oVC2hnz11LE8Ug5BnYFUaw'
                      iv_buyer = '6009bf877e4576bd3b7799f6').

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

    IF lo_http_client IS BOUND AND lo_rest_client IS BOUND.

      CONCATENATE '/ext/s4/' iv_buyer '/supplier' INTO lv_url.
*      lv_url = '/ext/s4/5fb7fbbc46e0fb00060c56ec/supplier'.

      cl_http_utility=>set_request_uri(
        EXPORTING
          request = lo_http_client->request    " HTTP Framework (iHTTP) HTTP Request
          uri     = lv_url                     " URI String (in the Form of /path?query-string)
      ).

* serialize data into gs_json, skipping initial fields and converting ABAP field names into camelCase
      lv_body = /ui2/cl_json=>serialize( data = ws_req_body pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
*      WRITE:/ lv_body.

      cl_demo_output=>write_json( lv_body ).
      cl_demo_output=>display( ).

* Set Payload or body ( JSON or XML)
      lo_request = lo_rest_client->if_rest_client~create_request_entity( ).
      lo_request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_json ).
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

** JSON to ABAP
*     DATA lr_json_deserializer TYPE REF TO cl_trex_json_deserializer.
*     TYPES: BEGIN OF ty_json_res,
*            token TYPE string,
*            END OF ty_json_res.
*     DATA: json_res TYPE ty_json_res.
*     CREATE OBJECT lr_json_deserializer.
*     lr_json_deserializer->deserialize( EXPORTING json = response IMPORTING abap = json_res ).


      WRITE: http_status.
      WRITE: reason.
      WRITE: response.

      CLEAR: http_status,reason,response.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
