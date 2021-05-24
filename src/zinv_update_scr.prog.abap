*&---------------------------------------------------------------------*
*& Include          ZINV_UPDATE_SCR
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1.
SELECT-OPTIONS : s_BELNR FOR s_scrn-BELNR,
                 s_time  FOR s_scrn-utime,
                 s_date  FOR s_scrn-udate.
SELECTION-SCREEN END OF BLOCK b1.
