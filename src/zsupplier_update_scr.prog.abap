*&---------------------------------------------------------------------*
*& Include          ZCDR_UPDATE_SCR
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1.

SELECT-OPTIONS : s_lifnr FOR lfa1-lifnr,
                 s_time  FOR cdhdr-utime,
                 s_date  FOR cdhdr-udate.

SELECTION-SCREEN END OF BLOCK b1.
