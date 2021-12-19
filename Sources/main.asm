;*******************************************************************************
                    #Uses     qg8.inc
;*******************************************************************************

LCD_EN              pin       PTBD,2
Y4                  pin       PTBD,0
Y2                  pin       PTBD,1
Y3                  pin       PTBD,0

STROBE              pin       PTBD,3

;*******************************************************************************

                    #Uses     mem.inc
                    #Uses     rtc_tec.sub
                    #Uses     adc.sub
                    #Uses     date_time.sub
                    #Uses     keypad.sub
                    #Uses     lcd.sub
                    #Uses     mcuinit.sub
                    #Uses     pwm.sub

;*******************************************************************************
                    #ROM
;*******************************************************************************

_Startup            proc
                    ldhx      #STACKTOP           ; __SEG_END_SSTACK ; initialize the stack pointer
                    txs
                    cli                           ; enable interrupts
                    lda       #$53
                    sta       SOPT1               ; disable watchdog

                    mov       #%11111111,PTADD    ; set data direction for for 0-7 in port A to an output
                    clr       onoff
                    jsr       init_LCD

                    mov       #83,cntr5
                    mov       #83,cntr6
                    mov       #83,cntr7

                    mov       #%00001000,PTBD     ; clear LED's
                    bclr      STROBE
                    bset      STROBE
                    mov       #%00001001,PTBD
                    bclr      STROBE
                    bset      STROBE
                    bclr      Y3
;                   jsr       write_req
;                   jsr       ADC_init
                    clr       state
                    jsr       MCU_init            ; Call generated device initialization function

MainLoop            clr       c_hold
                    jsr       TEC_read
                    jsr       Convert_LM92_temp
                    clr       press_pound
                    jsr       clear_display
                    jsr       second_line
                    jsr       write_T92
                    jsr       reset_cursor
                    jsr       write_Mode_ABC
Read_ABC
                    jsr       read_keypad
                    mov       n,press_value
                    jsr       read_keypad
                    tst       press_pound
                    beq       MainLoop
                    lda       press_value
                    cbeqa     #10,A_select
                    cbeqa     #11,B_select1
                    cbeqa     #12,C_select1
                    bra       MainLoop

;*******************************************************************************

B_select1           jmp       B_select
C_select1           jmp       C_select

;*******************************************************************************

A_select            proc
                    clr       press_pound
                    jsr       clear_display
                    jsr       write_Enter_Tset
                    jsr       second_line
                    jsr       write_Enter_10_40C
                    jsr       read_keypad
                    bsr       A_keypad_errorcheck
                    mov       n,temp_tens
                    jsr       read_keypad
                    bsr       A_keypad_errorcheck
                    mov       n,temp_ones
                    jsr       read_keypad
                    lda       press_pound
                    bne       A_calc

A_error             clr       press_pound
                    jsr       clear_display
                    jsr       write_Enter_Tset
                    jsr       write_error
                    jsr       second_line
                    jsr       write_Enter_10_40C
                    jsr       read_keypad
                    bsr       A_keypad_errorcheck
                    mov       n,temp_tens
                    jsr       read_keypad
                    bsr       A_keypad_errorcheck
                    mov       n,temp_ones
                    jsr       read_keypad
                    lda       press_pound
                    beq       A_error
                    bra       A_calc

;*******************************************************************************

A_keypad_errorcheck proc
                    lda       n
                    cbeqa     #10,A_error
                    cbeqa     #11,A_error
                    cbeqa     #12,A_error
                    cbeqa     #13,A_error
                    cbeqa     #14,A_error
                    rts

;*******************************************************************************

A_calc              proc
                    lda       temp_tens
                    ldx       #10
                    mul
                    add       temp_ones
                    sta       a_temp
                    sub       #10
                    bmi       A_error
                    lda       a_temp
                    sub       #40
                    bpl       A_error

                    jsr       clear_display
                    jsr       TEC_read
                    jsr       Convert_LM92_temp
                    lda       final_temp
                    sub       a_temp
                    bmi       A_heat
                    bpl       A_cool
                    bra       A_error

A_heat
                    mov       #1,state
                    jsr       reset_cursor
                    jsr       write_Heating_to
                    lda       temp_tens
                    add       #'0'
                    sta       tens
                    lda       temp_ones
                    add       #'0'
                    sta       ones
                    jsr       lcd_temp_mark
                    jsr       TEC_read
                    jsr       Convert_LM92_temp
                    jsr       DelayLoop2
                    jsr       second_line
                    jsr       write_T92
                    lda       final_temp
                    cbeq      a_temp,A_off1
                    bra       A_heat

A_cool
                    jsr       TEC_read
                    jsr       Convert_LM92_temp
                    mov       #2,state
                    jsr       reset_cursor
                    jsr       write_Cooling_to
                    lda       temp_tens
                    add       #'0'
                    sta       tens
                    lda       temp_ones
                    add       #'0'
                    sta       ones
                    jsr       lcd_temp_mark
                    jsr       TEC_read
                    jsr       Convert_LM92_temp
                    jsr       DelayLoop2
                    jsr       second_line
                    jsr       write_T92
                    lda       final_temp
                    cbeq      a_temp,A_off1
                    bra       A_cool

A_off1              jsr       clear_display

A_off2              clr       state
                    jsr       TEC_read
                    jsr       Convert_LM92_temp
                    jsr       reset_cursor
                    jsr       write_A_TEC_off
                    jsr       second_line
                    jsr       write_T92
                    jsr       read_keypad
                    bra       A_off2

;*******************************************************************************

B_select            proc
                    clr       press_pound
                    jsr       clear_display
                    jsr       write_TEC_function
                    jsr       second_line
                    jsr       write_1_Heat_0_Cool
                    jsr       read_keypad
                    lda       n
                    sub       #2
                    bpl       B_error
                    mov       n,b_state
                    jsr       read_keypad
                    lda       press_pound
                    beq       B_error
                    bra       B_time

B_error
                    clr       press_pound
                    jsr       clear_display
                    jsr       write_TEC_function
                    jsr       write_error
                    jsr       second_line
                    jsr       write_1_Heat_0_Cool
                    jsr       read_keypad
                    lda       n
                    sub       #2
                    bpl       B_error
                    mov       n,b_state
                    jsr       read_keypad
                    lda       press_pound
                    beq       B_error

B_time              clr       press_pound
                    jsr       clear_display
                    jsr       write_Time_in_seconds
                    jsr       second_line
                    jsr       write_Enter_0_180
                    jsr       read_keypad         ; 1st digit (hundreds)
                    lda       n
                    sub       #10
                    bpl       B_time_error
                    mov       n,b_time_h
                    jsr       read_keypad         ; 2nd digit (tens)
                    lda       press_pound
                    cbeqa     #1,B_time_1dig_send
                    lda       n
                    sub       #10
                    bpl       B_time_error
                    mov       n,b_time_t
                    jsr       read_keypad         ; 3rd digit (ones)
                    lda       press_pound
                    cbeqa     #1,B_time_2dig_send
                    lda       n
                    sub       #10
                    bpl       B_time_error
                    mov       n,b_time_o
                    jsr       read_keypad
                    lda       press_pound
                    beq       B_time_error
                    bra       B_time_3dig_send

B_time_1dig_send
                    bra       B_time_1dig

B_time_2dig_send
                    bra       B_time_2dig

B_time_3dig_send
                    bra       B_time_3dig

B_time_error
                    clr       press_pound
                    jsr       clear_display
                    jsr       write_Time_in_seconds
                    jsr       write_error
                    jsr       second_line
                    jsr       write_Enter_0_180
                    jsr       read_keypad         ; 1st digit (hundreds)
                    lda       n
                    sub       #10
                    bpl       B_time_error
                    mov       n,b_time_h
                    jsr       read_keypad         ; 2nd digit (tens)
                    lda       press_pound
                    cbeqa     #1,B_time_1dig
                    lda       n
                    sub       #10
                    bpl       B_time_error
                    mov       n,b_time_t
                    jsr       read_keypad         ; 3rd digit (ones)
                    lda       press_pound
                    cbeqa     #1,B_time_2dig
                    lda       n
                    sub       #10
                    bpl       B_time_error
                    mov       n,b_time_o
                    jsr       read_keypad
                    lda       press_pound
                    beq       B_time_error
                    bra       B_time_3dig

B_time_error_send
                    bra       B_time_error

B_time_1dig
                    mov       b_time_h,b_time_total
                    bra       B_heat_or_cool

B_time_2dig
                    lda       b_time_h
                    ldx       #10
                    mul
                    add       b_time_t
                    sta       b_time_total
                    bra       B_heat_or_cool

B_time_3dig
                    lda       b_time_h
                    ldx       #100
                    mul
                    add       b_time_o
                    sta       b_time_total
                    lda       b_time_t
                    ldx       #10
                    mul
                    add       b_time_total
                    sta       b_time_total
                    lda       b_time_total
                    sub       #181
                    bpl       B_time_error_send

B_heat_or_cool      jsr       RTC_write
                    jsr       RTC_read
                    jsr       clear_display
                    lda       b_state
                    beq       B_cool
                    cbeqa     #1,B_heat
                    bra       B_heat_or_cool

B_heat
                    mov       #1,state
                    jsr       TEC_read
                    jsr       Convert_LM92_temp
                    jsr       RTC_read
                    bsr       B_seconds_conv
                    jsr       DelayLoop2
                    jsr       reset_cursor
                    jsr       write_Heating_t
                    bsr       B_calc_seconds
                    jsr       seconds_temp_write
                    jsr       second_line
                    jsr       write_T92
                    lda       b_time_total
                    cbeq      seconds_temp,B_off
                    bra       B_heat

B_cool
                    mov       #2,state
                    jsr       TEC_read
                    jsr       Convert_LM92_temp
                    jsr       RTC_read
                    bsr       B_seconds_conv
                    jsr       DelayLoop2
                    jsr       reset_cursor
                    jsr       write_Cooling_t
                    bsr       B_calc_seconds
                    jsr       seconds_temp_write
                    jsr       second_line
                    jsr       write_T92
                    lda       b_time_total
                    cbeq      seconds_temp,B_off
                    bra       B_cool

B_off
                    clr       state
                    jsr       clear_display
                    jsr       write_B_TEC_off
                    jsr       second_line
                    jsr       write_T92
                    jsr       read_keypad
                    bra       B_off

;*******************************************************************************

B_calc_seconds      proc
                    lda       minutes
                    ldx       #60
                    mul
                    add       seconds_temp
                    sta       seconds_temp
                    rts

;*******************************************************************************

B_seconds_conv      proc
                    clr       seconds_temp
                    lda       seconds
                    and       #%00001111
                    sta       seconds_temp
                    lda       seconds
                    nsa
                    and       #%00001111
                    ldx       #10
                    mul
                    add       seconds_temp
                    sta       seconds_temp
                    rts

;*******************************************************************************

C_keypad_errorcheck proc
                    lda       n
                    cbeqa     #10,C_error
                    cbeqa     #11,C_error
                    cbeqa     #12,C_error
                    cbeqa     #13,C_error
                    cbeqa     #14,C_error
                    rts

;*******************************************************************************

C_error             proc
                    clr       press_pound
                    jsr       clear_display
                    jsr       write_Enter_Tset
                    jsr       write_error
                    jsr       second_line
                    jsr       write_Enter_10_40C
                    jsr       read_keypad
                    bsr       C_keypad_errorcheck
                    mov       n,temp_tens
                    jsr       read_keypad
                    bsr       C_keypad_errorcheck
                    mov       n,temp_ones
                    jsr       read_keypad
                    lda       press_pound
                    beq       C_error
                    bra       C_calc

;*******************************************************************************

C_select            proc
                    clr       press_pound
                    jsr       clear_display
                    jsr       write_Target_Temp
                    jsr       second_line
                    jsr       write_Enter_10_40C
                    jsr       read_keypad
                    bsr       C_keypad_errorcheck
                    mov       n,temp_tens
                    jsr       read_keypad
                    bsr       C_keypad_errorcheck
                    mov       n,temp_ones
                    jsr       read_keypad
                    lda       press_pound
                    beq       C_error
          ;--------------------------------------
C_calc              lda       temp_tens
                    ldx       #10
                    mul
                    add       temp_ones
                    sta       c_temp
                    lda       c_temp
                    sub       #10
                    bmi       C_error
                    lda       c_temp
                    sub       #40
                    bpl       C_error
          ;-------------------------------------- ;Heat or Cool
                    jsr       clear_display
                    jsr       TEC_read
                    jsr       Convert_LM92_temp
                    lda       final_temp
                    sub       c_temp
                    bpl       Cool@@
          ;--------------------------------------
Heat@@              jsr       TEC_read
                    jsr       Convert_LM92_temp
                    mov       #1,state
                    jsr       reset_cursor
                    jsr       write_Heating_to
                    lda       temp_tens
                    add       #'0'
                    sta       tens
                    lda       temp_ones
                    add       #'0'
                    sta       ones
                    jsr       lcd_temp_mark
                    jsr       DelayLoop2
                    jsr       second_line
                    jsr       write_T92
                    lda       final_temp
                    cbeq      c_temp,Off1@@
                    bra       Heat@@

Cool@@              jsr       TEC_read
                    jsr       Convert_LM92_temp
                    mov       #2,state
                    jsr       reset_cursor
                    jsr       write_Cooling_to
                    lda       temp_tens
                    add       #'0'
                    sta       tens
                    lda       temp_ones
                    add       #'0'
                    sta       ones
                    jsr       lcd_temp_mark
                    jsr       DelayLoop2
                    jsr       second_line
                    jsr       write_T92
                    lda       final_temp
                    cbeq      c_temp,Off1@@
                    bra       Cool@@

Off1@@              jsr       clear_display

Off2@@              clr       state
                    mov       #1,c_hold
                    jsr       read_keypad
                    bra       Off2@@

;*******************************************************************************

Restart             proc
Loop@@              mov       state,previous_state
                    clr       seconds
                    jsr       RTC_write

RunPre@@            jsr       RTC_read
                    lda       seconds
                    and       #%00000001
                    bne       ClearUpdate@@
;                   brset     seconds,ClearUpdate@@
                    lda       update
                    cbeqa     #1,UpdateNo@@

                    jsr       RTC_read
                    lda       seconds
                    and       #%00000001
                    beq       UpdateYes@@
ClearUpdate@@       clr       update
UpdateNo@@          jsr       RTC_read
                    jsr       reset_cursor
                    jsr       write_TEC_state
                    jsr       second_line
                    jsr       write_T92
                    jsr       write_KatT
                    jsr       seconds_write
                    jsr       read_keypad
                    jsr       read_keypad
                    jsr       read_keypad
                    jsr       read_keypad
                    jsr       read_keypad
                    lda       state
                    cbeq      previous_state,RunPre@@
                    bra       Loop@@

UpdateYes@@         jsr       TEC_read
                    jsr       Convert_LM92_temp
                    jsr       RTC_read
                    jsr       reset_cursor
                    jsr       write_TEC_state
                    jsr       second_line
                    jsr       write_T92
                    jsr       write_KatT
                    jsr       seconds_write
                    jsr       read_keypad
                    jsr       read_keypad
                    jsr       read_keypad
                    jsr       read_keypad
                    jsr       read_keypad
                    mov       #1,update
                    bra       RunPre@@

;*******************************************************************************

DelayLoop2          proc
_2@@                dbnz      cntr5,_3@@
                    mov       #83,cntr5
                    bra       Done@@

_3@@                dbnz      cntr6,_4@@
                    mov       #83,cntr6
                    bra       _2@@

_4@@                dbnz      cntr7,_4@@
                    mov       #20,cntr7
                    bra       _3@@

Done@@              mov       #83,cntr5
                    mov       #83,cntr6
                    mov       #83,cntr7
                    rts

;*******************************************************************************
                    #sp
;*******************************************************************************
