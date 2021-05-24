*&---------------------------------------------------------------------*
*& Include          ZGR_UPDATE_TOP
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION DEFERRED.

TYPES: BEGIN OF ty_scrn,
         mblnr TYPE matdoc-mblnr,
         ebeln TYPE matdoc-ebeln,
         udate TYPE matdoc-cpudt,
         utime TYPE matdoc-cputm,
       END OF ty_scrn.

TYPES: BEGIN OF ty_data,
         mblnr TYPE matdoc-mblnr,
         mjahr TYPE matdoc-mjahr,
         vgart TYPE matdoc-vgart,
         blart TYPE matdoc-blart,
         bwart TYPE matdoc-bwart,
         cpudt TYPE matdoc-cpudt,
         cputm TYPE matdoc-cputm,
         ebeln TYPE matdoc-ebeln,
       END OF ty_data.

DATA: gt_data TYPE STANDARD TABLE OF ty_data,
      s_scrn  TYPE ty_scrn,
      go_alv  TYPE REF TO if_salv_gui_table_ida,
      go_obj  TYPE REF TO lcl_class.

DATA: o_alv TYPE REF TO cl_salv_table.
