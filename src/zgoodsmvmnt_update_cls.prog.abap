*&---------------------------------------------------------------------*
*& Include          ZGR_UPDATE_CLS
*&---------------------------------------------------------------------*
CLASS lcl_class DEFINITION.

  PUBLIC SECTION.

    METHODS : get_data,trigger_po.

    DATA : lt_po TYPE range_ebeln_in_t.

ENDCLASS.

CLASS lcl_class IMPLEMENTATION.

  METHOD get_data.

    DATA :ls_time    TYPE range_tims,
          lv_jobname TYPE tbtcm-jobname.

    CALL FUNCTION 'GET_JOB_RUNTIME_INFO'
      IMPORTING
        jobname         = lv_jobname
      EXCEPTIONS
        no_runtime_info = 1
        OTHERS          = 2.

    IF lv_jobname CS 'ZGOODSMVNT_UPDATE_REPORT'.

      SELECT SINGLE name, sign, opti, low, high INTO @DATA(gs_from)
          FROM tvarvc
          WHERE name = 'ZGR_FROM_TIME'
          AND type = 'P'.
      IF sy-subrc = 0.
        ls_time-sign = 'I'.
        ls_time-option = 'GT'.
        ls_time-high = ''.
        ls_time-low = gs_from-low.

        MODIFY s_time[] FROM ls_time INDEX 1 TRANSPORTING low.
      ENDIF.

      UPDATE tvarvc SET low = sy-uzeit WHERE name = 'ZGR_FROM_TIME'.

    ENDIF.

*Get details of Material Document
    SELECT
       mblnr ,
       mjahr ,
       vgart ,
       blart ,
       bwart ,
       cpudt ,
       cputm ,
       ebeln
      INTO TABLE @gt_data
      FROM matdoc
      WHERE mblnr IN @s_mblnr
      AND ebeln IN @s_ebeln
      AND cpudt IN @s_date
      AND cputm IN @s_time.

    IF sy-subrc = 0.

      DELETE gt_data WHERE ebeln IS INITIAL.
      DELETE ADJACENT DUPLICATES FROM gt_data COMPARING ebeln.

      LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<fs_data>).
        lt_po = VALUE range_ebeln_in_t( BASE CORRESPONDING #( lt_po ) ( sign   = 'I'
                                                                        option = 'EQ'
                                                                        low    = <fs_data>-ebeln ) ).
      ENDLOOP.
      IF me->lt_po IS NOT INITIAL.
        SORT me->lt_po.
        DELETE ADJACENT DUPLICATES FROM me->lt_po.
        trigger_po( ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD trigger_po.

    DATA: lv_name   TYPE tbtcjob-jobname,
          lv_jcount TYPE tbtcjob-jobcount.

    lv_name = |PO_GoodsMvmnt{ sy-datum }{ sy-uzeit }|.
    CALL FUNCTION 'JOB_OPEN'
      EXPORTING
        jobname          = lv_name
      IMPORTING
        jobcount         = lv_jcount
      EXCEPTIONS
        cant_create_job  = 1
        invalid_job_data = 2
        jobname_missing  = 3
        OTHERS           = 4.
    IF sy-subrc = 0.
      SUBMIT zpo_update_report AND RETURN
         VIA JOB lv_name NUMBER lv_jcount
        WITH s_ebeln IN me->lt_po[].
      IF sy-subrc = 0.
        CALL FUNCTION 'JOB_CLOSE'
          EXPORTING
            jobcount             = lv_jcount
            jobname              = lv_name
            strtimmed            = abap_true
          EXCEPTIONS
            cant_start_immediate = 1
            invalid_startdate    = 2
            jobname_missing      = 3
            job_close_failed     = 4
            job_nosteps          = 5
            job_notex            = 6
            lock_failed          = 7
            invalid_target       = 8
            invalid_time_zone    = 9
            OTHERS               = 10.
        IF sy-subrc <> 0.

        ENDIF.
      ENDIF.
    ENDIF.
    CLEAR me->lt_po[].

  ENDMETHOD.

ENDCLASS.
