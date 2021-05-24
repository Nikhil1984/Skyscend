*&---------------------------------------------------------------------*
*& Include          ZNONPOINV_UPDATE_SCR
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1.
SELECT-OPTIONS : s_belnr FOR s_scrn-belnr,
                 s_date  FOR s_scrn-udate,
                 s_time  FOR s_scrn-utime.
PARAMETERS: p_gjahr TYPE gjahr.
SELECTION-SCREEN END OF BLOCK b1.
