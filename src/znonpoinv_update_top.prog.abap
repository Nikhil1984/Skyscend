*&---------------------------------------------------------------------*
*& Include          ZNONPOINV_UPDATE_TOP
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION DEFERRED.
TYPES: BEGIN OF ty_scrn,
         belnr TYPE acdoca-belnr,
         utime TYPE bkpf-cputm,
         udate TYPE bkpf-cpudt,
       END OF ty_scrn.

*TYPES: BEGIN OF ty_data,
*         belnr      TYPE acdoca-belnr,
*         gjahr      TYPE acdoca-gjahr,
*         rbukrs     TYPE acdoca-rbukrs,
*         bldat      TYPE acdoca-bldat,
*         budat      TYPE acdoca-budat,
*         rtcur      TYPE acdoca-rtcur,
*         blart      TYPE acdoca-blart,
*         augbl      TYPE acdoca-augbl,
*         xreversing TYPE acdoca-xreversing,
*         xreversed  TYPE acdoca-xreversed,
*         awref_rev  TYPE acdoca-awref_rev,
*         timestamp  TYPE acdoca-timestamp,
*         hsl        TYPE acdoca-hsl,
*         awref      TYPE acdoca-awref,
*         buzei      TYPE acdoca-buzei,
*         zuonr      TYPE acdoca-zuonr,
*         bschl      TYPE acdoca-bschl,
*         sgtxt      TYPE acdoca-sgtxt,
*         gkont      TYPE acdoca-gkont,
*         accas      TYPE acdoca-accas,
*         re_bukrs   TYPE acdoca-re_bukrs,
*         lifnr      TYPE acdoca-lifnr,
*       END OF ty_data.

TYPES: BEGIN OF ty_data,
         belnr     TYPE bkpf-belnr,
         gjahr     TYPE bkpf-gjahr,
         budat     TYPE bkpf-budat,
         xblnr     TYPE bkpf-xblnr,
         bukrs     TYPE bkpf-bukrs,
         blart     TYPE bkpf-blart,
         waers     TYPE bkpf-waers,
         bstat     TYPE bkpf-bstat,
         stblg     TYPE bkpf-stblg,
         stjah     TYPE bkpf-stjah,
         cpudt     TYPE bkpf-cpudt,
         cputm     TYPE bkpf-cputm,
         xreversal TYPE bkpf-xreversal,
         buzei     TYPE bseg-buzei,
         lifnr     TYPE bseg-lifnr,
         wskto     TYPE bseg-wskto,
         zlspr     TYPE bseg-zlspr,
         wmwst     TYPE bseg-wmwst,
         erfme     TYPE bseg-erfme,
         matnr     TYPE bseg-matnr,
         menge     TYPE bseg-menge,
         mwskz     TYPE bseg-mwskz,
         wrbtr     TYPE bseg-wrbtr,
         werks     TYPE bseg-werks,
         koart     TYPE bseg-koart,
         sgtxt     TYPE bseg-sgtxt,
         dmbtr     TYPE bseg-dmbtr,
*         bschl      TYPE bseg-bschl,
*         sgtxt      TYPE bseg-sgtxt,
*         gkont      TYPE bseg-gkont,
*         accas      TYPE bseg-accas,
*         re_bukrs   TYPE bseg-re_bukrs,
*         lifnr      TYPE bseg-lifnr,
       END OF ty_data.

DATA: gt_data TYPE STANDARD TABLE OF ty_data,
      s_scrn  TYPE ty_scrn,
      go_alv  TYPE REF TO if_salv_gui_table_ida,
      go_obj  TYPE REF TO lcl_class.

DATA: o_alv TYPE REF TO cl_salv_table.
