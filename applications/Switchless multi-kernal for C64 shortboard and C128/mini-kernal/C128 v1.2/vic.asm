vicinit
        ldx #48
vicloop lda victbl,x    ; initialize vic
        sta VICREG,x
        dex
        bpl vicloop
        rts

victbl  byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0         ;reg  0-16 (sprite pos)
        byte $1b,$ff,0,0,0,$08,0,$14,$ff,1,0,0,0,0,0   ;reg 17-31 (control)
        byte BODCOL,BAKCOL,1,2,3,1,2,0,1,2,3,4,5,6,7   ;reg 32-46 (colors)
        byte $ff,$fc                                   ;reg 47-48 (keylines & 2MHz) 


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
