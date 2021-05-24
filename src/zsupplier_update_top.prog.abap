*&---------------------------------------------------------------------*
*& Include          ZCDR_UPDATE_TOP
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION DEFERRED.
TABLES: lfa1, cdhdr, cdpos.

DATA: go_alv TYPE REF TO if_salv_gui_table_ida,
      go_obj TYPE REF TO lcl_class.

DATA: o_alv TYPE REF TO cl_salv_table.
