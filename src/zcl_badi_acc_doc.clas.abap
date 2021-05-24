class ZCL_BADI_ACC_DOC definition
  public
  final
  create public .

*"* public components of class ZCL_BADI_ACC_DOC
*"* do not include other source files here!!!
public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_ACC_DOCUMENT .
protected section.
*"* protected components of class ZCL_BADI_ACC_DOC
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_BADI_ACC_DOC
*"* do not include other source files here!!!
ENDCLASS.



CLASS ZCL_BADI_ACC_DOC IMPLEMENTATION.


METHOD IF_EX_ACC_DOCUMENT~CHANGE .

***********************************************************************
* Example to move fields from BAPI parameter EXTENSION2 to structure  *
* ACCIT (accounting document line items).                             *
* The dictionary structure (content for EXTENSION2-STRUCTURE) must    *
* contain field POSNR, (TYPE POSNR_ACC) to indentify the correct line *
* item of the internal table ACCIT.                                   *
***********************************************************************

*  DATA: wa_extension   TYPE bapiparex,
*        ext_value(960) TYPE c,
*        wa_accit       TYPE accit,
*        WA_ACCHD       TYPE ACCHD,
*        l_ref          TYPE REF TO data.
*
*  FIELD-SYMBOLS: <l_struc> TYPE ANY,
*                 <l_field> TYPE ANY.
*
*  SORT c_extension2 BY structure.
*
*  LOOP AT c_extension2 INTO wa_extension.
*    AT NEW structure.
*      CREATE DATA l_ref TYPE (wa_extension-structure).
*      ASSIGN l_ref->* TO <l_struc>.
*    ENDAT.
*    CONCATENATE wa_extension-valuepart1 wa_extension-valuepart2
*                wa_extension-valuepart3 wa_extension-valuepart4
*           INTO ext_value.
*    MOVE ext_value TO <l_struc>.
*    ASSIGN COMPONENT 'POSNR' OF STRUCTURE <l_struc> TO <l_field>.
*    READ TABLE c_accit WITH KEY posnr = <l_field>
*          INTO wa_accit.
*    IF sy-subrc IS INITIAL.
*      MOVE-CORRESPONDING <l_struc> TO wa_accit.
*      MODIFY c_accit FROM wa_accit INDEX sy-tabix.
*    ENDIF.
*  ENDLOOP.

*** Local variable
  DATA: lt_extension2 TYPE STANDARD TABLE OF bapiparex.

*** Pointers
  FIELD-SYMBOLS: <fs_table>  TYPE STANDARD TABLE,
                 <fs_header> TYPE any,
                 <fs_field>  TYPE any,
                 <fs_ext>    TYPE bapiparex,
                 <fs_ext2>   TYPE bapiparex.

*** Delete duplicate records
  lt_extension2[] = c_extension2[].
  SORT lt_extension2 BY structure  ASCENDING
                        valuepart1 ASCENDING
                        valuepart2 ASCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_extension2 COMPARING structure
                                                          valuepart1
                                                          valuepart2.

****************************************************************
*-- Below code is shortdumping while testing RFRECEEP_SINGLE
*-- Commented for now - Need to test this code once uncommented
****************************************************************

**** Read all values to update
*  LOOP AT lt_extension2 ASSIGNING <fs_ext>.
*
****   Get Header
*      UNASSIGN <fs_header>.
*      ASSIGN (<fs_ext>-valuepart2) TO <fs_header>.
*
****   Found data
*      CHECK sy-subrc = 0.
*
*
****   Get all fields of same position
*      LOOP AT c_extension2 ASSIGNING <fs_ext2>
*                               WHERE structure  = <fs_ext>-structure
*                                 AND valuepart1 = <fs_ext>-valuepart1
*                                 AND valuepart2 = <fs_ext>-valuepart2.
*
****     Get field
*        UNASSIGN <fs_field>.
*        ASSIGN COMPONENT <fs_ext2>-valuepart3 OF STRUCTURE <fs_header>
*                                              TO <fs_field>.
*
****     Update new value
*        CHECK sy-subrc = 0.
*
*        <fs_field> = <fs_ext2>-valuepart4.
*
*      ENDLOOP.
*
*
*ENDLOOP.

ENDMETHOD.                    "IF_EX_ACC_DOCUMENT~CHANGE


method IF_EX_ACC_DOCUMENT~FILL_ACCIT.
endmethod.
ENDCLASS.
