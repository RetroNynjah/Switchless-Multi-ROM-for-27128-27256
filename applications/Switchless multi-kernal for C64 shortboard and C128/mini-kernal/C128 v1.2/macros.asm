; copy character set to VDC address $2000
; vdcchars from_start_address, from_end_addr
defm    vdcchars
        lda #</1
        ldy #>/1
        sta $da         ; start of data lo byte
        sty $db         ; start of data hi byte
        lda #>/2
        sta $de         ; end of data hi byte

        ldx #28         ; VDC ram char addess = $2000
        lda #$20
        jsr vdcreg_w

        ldx #18         ; VDC ram (2000) hi byte
        lda #$20
        jsr vdcreg_w
        ldx #19         ; VDC ram (2000) lo byte
        lda #$00
        jsr vdcreg_w

        ldy #0          
loop
        ldx #31         
@1                      ; copy 8 bytes of character data from ram to vdc     
        lda ($da),y
        jsr vdcreg_w    
        iny
        cpy #8
        bcc @1

        lda #0
@2                      ; add 8 empty lines to fill all 16 vdc character lines
        jsr vdcreg_w
        dey
        bne @2

        clc
        lda $da
        adc #8
        sta $da
        bcc loop
        inc $db
        lda $db
        cmp $de
        bne loop
        endm


; vdcmenu from_start_address
; copies 25x40 chars plus padding from from_start_address to $0000-$07ff
defm    vdcmenu
        lda #</1
        ldy #>/1
        sta $da         ; start of data lo byte
        sty $db         ; start of data hi byte
        tya
        clc
        adc #08
        sta $de      ; end of data hi byte

        ldx #18         ; VDC ram (0000) hi byte
        lda #$00
        jsr vdcreg_w
        ldx #19         ; VDC ram (0000) lo byte
        lda #$00
        jsr vdcreg_w

@rowloop
        ; add 20 spaces before text
        lda #$20
        ldy #20
        jsr vdcfill
        ldx #$00
        ldy #$00
@charloop
        ; copy 40 characters of text to screen
        cpy #40
        beq @endpadding
        lda ($da),y
        ldx #31
        jsr vdcreg_w
        iny
        cpy #40
        bne @charloop
@endpadding
        ; add 20 spaces after text
        lda #$20
        ldy #20
        jsr vdcfill
        lda $da
        clc
        adc #40
        sta $da
        bcc @rowloop
        inc $db
        lda $db
        cmp $de        ; reached end of data ?
        bne @rowloop
        endm


     