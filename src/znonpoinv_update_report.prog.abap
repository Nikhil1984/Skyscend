*&---------------------------------------------------------------------*
*& Report ZNONPOINV_UPDATE_REPORT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT znonpoinv_update_report.

************************************************************************
*                          I N C L U D E S                             *
************************************************************************
INCLUDE ZNONPOINV_UPDATE_TOP.
INCLUDE ZNONPOINV_UPDATE_SCR.
INCLUDE ZNONPOINV_UPDATE_CLS.

***********************************************************************
*                    I N I T I A L I Z A T I O N                       *
************************************************************************
INITIALIZATION.
  CREATE OBJECT go_obj.

*************************************************************************
*                     Start of Selection
*************************************************************************
START-OF-SELECTION.
  go_obj->get_data( ).

*************************************************************************
*                     End of Selection
*************************************************************************
END-OF-SELECTION.
  go_obj->process_data( ).
