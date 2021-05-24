*&---------------------------------------------------------------------*
*& Include          ZGR_UPDATE_TOP
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION DEFERRED.
TYPES: BEGIN OF ty_scrn,
         mblnr TYPE matdoc-mblnr,
         udate TYPE matdoc-cpudt,
         utime TYPE matdoc-cputm,
       END OF ty_scrn.

TYPES: BEGIN OF ty_data,
         mblnr TYPE matdoc-mblnr,
         mjahr TYPE matdoc-mjahr,
         vgart TYPE matdoc-vgart,
         blart TYPE matdoc-blart,
         bldat TYPE matdoc-bldat,
         budat TYPE matdoc-budat,
         cpudt TYPE matdoc-cpudt,
         cputm TYPE matdoc-cputm,
         tcode TYPE matdoc-tcode,
         zeile TYPE matdoc-zeile,
         bwart TYPE matdoc-bwart,
         lifnr TYPE matdoc-lifnr,
         charg TYPE matdoc-charg,
         matnr TYPE matdoc-matnr,
         werks TYPE matdoc-werks,
         lgort TYPE matdoc-lgort,
         dmbtr TYPE matdoc-dmbtr,
         shkum TYPE matdoc-shkum,
         menge TYPE matdoc-menge,
         meins TYPE matdoc-meins,
         erfme TYPE matdoc-erfme,
         erfmg TYPE matdoc-erfmg,
         ebeln TYPE matdoc-ebeln,
         ebelp TYPE matdoc-ebelp,
         frbnr TYPE matdoc-frbnr,
         xblnr TYPE matdoc-xblnr,
         sgtxt TYPE matdoc-sgtxt,
       END OF ty_data.

DATA: gt_data TYPE STANDARD TABLE OF ty_data,
      s_scrn  TYPE ty_scrn,
      go_alv  TYPE REF TO if_salv_gui_table_ida,
      go_obj  TYPE REF TO lcl_class.

DATA: o_alv TYPE REF TO cl_salv_table.
