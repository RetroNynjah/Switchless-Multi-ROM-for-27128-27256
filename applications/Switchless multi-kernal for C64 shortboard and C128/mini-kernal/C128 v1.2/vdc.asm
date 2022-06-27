; VDC functions

; fill 2kB of screen ram with spaces
vdcscreenclear
        lda #$00
        tay
        jsr vdcpos_w

        lda #$20        ; write a space
        ldx #31
        jsr vdcreg_w
        ldx #24
        jsr vdcreg_r    ; set copy/fill flag to 0
        and #%01111111
        jsr vdcreg_w
        ldy #$08        ; eigth characters
@loop   
        ldx #30
        lda #$fe        ; fill 254 times (2kB)
        jsr vdcreg_w
        dey
        bne @loop

        lda #$00
        tay
        jsr vdcpos_w
        rts


vdcreg_w
        stx VDCADR
@loop   bit VDCADR
        bpl @loop
        sta VDCDAT
        rts

vdcreg_r
        stx VDCADR
@loop   bit VDCADR
        bpl @loop
        lda VDCDAT
        rts

; write byte at current vdc postition
; value in a
vdcbyte_w
        txa
        pha
        ldx #31
        jsr vdcreg_w
        pla
        tax
        rts
        
; set read/write position in memory
; low byte in a, high byte in y
vdcpos_w
        ldx #19
        jsr vdcreg_w
        tya
        dex
        jsr vdcreg_w
        rts

; write byte a, y number of times
vdcfill
        cpy #$00
        beq @nofill
        pha
        ldx #31
        jsr vdcreg_w
        cpy #$01
        beq @nofill
@fill
        ldx #24
        jsr vdcreg_r    ; set copy/fill flag to 0
        and #%01111111
        jsr vdcreg_w
        ldx #30
        tya
        sec
        sbc #$01        ; subtract one for the byte already written
        jsr vdcreg_w
@nofill
        pla
        rts


; highlight row stored in a
vdcrow_hl
        clc
        adc #$05 ; add five to row index to skip header rows
        sta $dc ; store selected row
        tya
        pha
        lda #$00
        ldy #$08
        jsr vdcpos_w
        
        ldx #$00
@rowloop
        txa
        pha
        cpx $dc
        bne @hloff
        beq @hl
@hloff
        ; inactive row, turn off highlight
        lda #VDC_CHRC+VDC_ALTERNATE
        ldy #80
        jsr vdcfill
        jmp @rowdone
@hl
        ; active row, turn on highlight
        lda #VDC_CHRCHL+VDC_ALTERNATE
        ldy #80
        jsr vdcfill
@rowdone
        pla
        tax
        inx
        cpx #25
        bne @rowloop
        pla
        tay
        rts


; CBM Kernal VDC initialization code below

vdcstart
        ldx #0          ;initialize 8563 (NTSC)
        jsr vdc_init
        lda vdcadr
        and #$07
        beq @50         ;...branch if old 8563R7
        ldx #vdcpat-vdctbl
        jsr vdc_init    ;...else apply -R8 patches
@50     bit palnts
        bpl @60         ;...branch if NTSC
        ldx #vdcpal-vdctbl
        jsr vdc_patch   ;...else apply PAL patches (318020-04 fix)        
@60
        rts


vdc_init
        ldy vdctbl,x    ;get 8563 register #
        bmi @10         ;...branch if end-of-table
        inx
        lda vdctbl,x    ;get data for this register
        inx
        sty vdcadr
        sta vdcdat
        bpl vdc_init    ;always

@10     inx
        rts


vdc_patch               ;(#318020-04   11/15/85   F.A.B.)

;  Corrected 8563 PAL initialization in IOINIT.  With a cheap monitor
;  there was interference with line frequency.  Both horizontal total
;  and vertical total have been adjusted. See also 'vdcpal' table.


        ldy #0          ;vdc register #0
        lda #$7f        ;PAL horizontal total
        sty vdcadr
        sta vdcdat

        jmp vdc_init    ;resume 'normal' PAL init & RTS



vdctbl  byte  0,$7e, 1,$50, 2,$66, 3,$49, 4,$20, 5,$00, 6,$19, 7,$1d   ;8563 NTSC
        byte  8,$00, 9,$07,10,$20,11,$07,12,$00,13,$00,14,$00,15,$00
        byte 20,$08,21,$00,23,$08,24,$20,25,$40,26,$f0,27,$00,28,$20
        byte 29,$07,34,$7d,35,$64,36,$05,22,$78,$ff

vdcpat  byte 25,$47, $ff               ;8563 patches

vdcpal  byte  4,$26, 7,$20,$ff         ;8563 PAL (318020-04 fix. see vdc_patch too)

