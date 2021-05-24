*&---------------------------------------------------------------------*
*& Include          ZCDR_UPDATE_SCR
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1.
SELECT-OPTIONS : s_ebeln FOR s_scrn-ebeln,
                 s_lifnr FOR s_scrn-lifnr,
                 s_time  FOR s_scrn-utime,
                 s_date  FOR s_scrn-udate.
SELECTION-SCREEN END OF BLOCK b1.
