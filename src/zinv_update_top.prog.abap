*&---------------------------------------------------------------------*
*& Include          ZINV_UPDATE_TOP
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION DEFERRED.
TYPES: BEGIN OF ty_scrn,
         belnr TYPE rbkp-belnr,
         udate TYPE rbkp-cpudt,
         utime TYPE rbkp-cputm,
       END OF ty_scrn.

TYPES: BEGIN OF ty_data,
         belnr  TYPE rbkp-belnr,
         gjahr  TYPE rbkp-gjahr,
         budat  TYPE rbkp-budat,
         xblnr  TYPE rbkp-xblnr,
         lifnr  TYPE rbkp-lifnr,
         bukrs  TYPE rbkp-bukrs,
         rmwwr  TYPE rbkp-rmwwr,
         wskto  TYPE rbkp-wskto,
         waers  TYPE rbkp-waers,
         rbstat TYPE rbkp-rbstat,
         xrech  TYPE rbkp-xrech,
         stblg  TYPE rbkp-stblg,
         stjah  TYPE rbkp-stjah,
         cpudt  TYPE rbkp-cpudt,
         cputm  TYPE rbkp-cputm,
         vgart  TYPE rbkp-vgart,
         zlspr  TYPE rbkp-zlspr,
         wmwst1 TYPE rbkp-wmwst1,
         buzei  TYPE rseg-buzei,
         ebeln  TYPE rseg-ebeln,
         ebelp  TYPE rseg-ebelp,
         matnr  TYPE rseg-matnr,
         menge  TYPE rseg-menge,
         mwskz  TYPE rseg-mwskz,
         werks  TYPE rseg-werks,
         bstme  TYPE rseg-bstme,
         bnkan  TYPE rseg-bnkan,
         wrbtr  TYPE rseg-wrbtr,
         txz01  TYPE ekpo-txz01,
         lgort  TYPE ekpo-lgort,
         maktx  TYPE makt-maktx,
       END OF ty_data.

TYPES: BEGIN OF ty_cdhdr,
         objectid   TYPE cdhdr-objectid,
         change_ind TYPE cdhdr-change_ind,
         udate      TYPE cdhdr-udate,
         utime      TYPE cdhdr-utime,
       END OF ty_cdhdr.

DATA: gt_data  TYPE STANDARD TABLE OF ty_data,
      gt_cdhdr TYPE STANDARD TABLE OF ty_cdhdr,
      s_scrn   TYPE ty_scrn,
      go_alv   TYPE REF TO if_salv_gui_table_ida,
      go_obj   TYPE REF TO lcl_class.

DATA: o_alv TYPE REF TO cl_salv_table.
