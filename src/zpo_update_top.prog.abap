*&---------------------------------------------------------------------*
*& Include          ZCDR_UPDATE_TOP
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION DEFERRED.
TYPES: BEGIN OF ty_scrn,
         ebeln TYPE ekko-ebeln,
         lifnr TYPE ekko-lifnr,
         udate TYPE cdhdr-udate,
         utime TYPE cdhdr-utime,
       END OF ty_scrn.

TYPES: BEGIN OF ty_data,
         ebeln    TYPE ekko-ebeln,
         ebelp    TYPE ekpo-ebelp,
         loekz    TYPE ekko-loekz,
         aedat    TYPE ekko-aedat,
         bukrs    TYPE ekko-bukrs,
         lifnr    TYPE ekko-lifnr,
         ekorg    TYPE ekko-ekorg,
         ekgrp    TYPE ekko-ekgrp,
         waers    TYPE ekko-waers,
         adrnr    TYPE ekko-adrnr,
         ihrez    TYPE ekko-ihrez,
         unsez    TYPE ekko-unsez,
         procstat TYPE ekko-procstat,
         zterm    TYPE ekko-zterm,
         matnr    TYPE ekpo-matnr,
         txz01    TYPE ekpo-txz01,
         loekz1   TYPE ekpo-loekz,
         werks    TYPE ekpo-werks,
         lgort    TYPE ekpo-lgort,
         menge    TYPE ekpo-menge,
         meins    TYPE ekpo-meins,
         bprme    type ekpo-bprme,
         bpumz    type ekpo-bpumz,
         bpumn    type ekpo-bpumn,
         netwr    TYPE ekpo-netwr,
         mwskz    TYPE ekpo-mwskz,
         dpdat    TYPE ekpo-dpdat,
         adrn2    TYPE ekpo-adrn2,
         bstae    TYPE ekpo-bstae,
         elikz    TYPE ekpo-elikz,
         erekz    TYPE ekpo-erekz,
         ctime    TYPE ekpo-creationtime,
       END OF ty_data.

TYPES: BEGIN OF ty_eket,
         ebeln TYPE eket-ebeln,
         ebelp TYPE eket-ebelp,
         etenr TYPE eket-etenr,
         eindt TYPE eket-eindt,
         menge TYPE eket-menge,
         uzeit TYPE eket-uzeit,
       END OF ty_eket.

TYPES: BEGIN OF ty_cdhdr,
         objectid   TYPE cdhdr-objectid,
         change_ind TYPE cdhdr-change_ind,
         udate      TYPE cdhdr-udate,
         utime      TYPE cdhdr-utime,
       END OF ty_cdhdr.

TYPES: BEGIN OF ty_adrc,
         addrnumber TYPE adrc-addrnumber,
         house_num1 TYPE adrc-house_num1,
         street     TYPE adrc-street,
         city1      TYPE adrc-city1,
         post_code1 TYPE adrc-post_code1,
         country    TYPE adrc-country,
         region     TYPE adrc-region,
       END OF ty_adrc.

TYPES: BEGIN OF t_poqty,
         ebeln  TYPE ekpo-ebeln,
         ebelp  TYPE ekpo-ebelp,
         grqty  TYPE ekpo-menge,
         pgrqty TYPE ekpo-menge,
         inqty  TYPE ekpo-menge,
         inamt  TYPE ekpo-netpr,
         pinqty TYPE ekpo-menge,
         pinamt TYPE ekpo-netpr,
       END OF t_poqty.

DATA: t_data  TYPE STANDARD TABLE OF ty_data,
      t_eket  TYPE STANDARD TABLE OF ty_eket,
      t_poqty TYPE STANDARD TABLE OF t_poqty,
      t_cdhdr TYPE STANDARD TABLE OF ty_cdhdr,
      t_adrc  TYPE STANDARD TABLE OF ty_adrc,
      s_scrn  TYPE ty_scrn,
      go_alv  TYPE REF TO if_salv_gui_table_ida,
      go_obj  TYPE REF TO lcl_class.

DATA: o_alv TYPE REF TO cl_salv_table.
