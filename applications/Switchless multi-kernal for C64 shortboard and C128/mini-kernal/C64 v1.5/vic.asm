
; initialize VIC registers
vicinit
        ldx #47
@vicloop 
        lda victbl-1,x    ; initialize vic
        sta VICREG-1,x
        dex
        bne @vicloop
        rts

victbl  byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;SPRITES (0-16)
        byte $9b,55,0,0,0,$08,0,$14,$0f,0,0,0,0,0,0 ;DATA (17-31) RC=311
        byte BODCOL,BAKCOL,1,2,3,4,0,1,2,3,4,5,6,7 ;32-46


vicclear        
        ldx #$00
        lda #$20
@clr                    ; clear 40 column screen
        sta $0400,x
        sta $0500,x
        sta $0600,x
        sta $0700,x
        inx
        bne @clr
        rts



; highlight row stored in a
vicrow_hl
        pha
        clc
        adc #$05 ; add five to row index to skip header rows
        sta $dc ; store selected row

        lda #<$d800
        ldy #>$d800
        sta $da         ; start of data lo byte
        sty $db         ; start of data hi byte

        ldx #0
@row_loop
        ldy #0
        cpx $dc
        beq @hl_on
        bne @hl_off
@hl_off
        ; inactive row, turn off highlight
        lda #CHRC
        jmp @chars
@hl_on
        lda #CHRCHL
@chars
        sta($da),y
        iny
        cpy #40
        bne @chars

@row_done
        inx
        cpx #25
        beq @done
        lda $da
        clc
        adc #40
        sta $da
        bcc @row_loop
        inc $db
        bne @row_loop
@done
        pla
        rts
