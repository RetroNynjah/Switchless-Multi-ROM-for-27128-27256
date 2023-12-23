
; initialize VIC registers
tedinit
        ldx #27
@tedloop 
        lda tedtbl-1,x    ; initialize vic
        sta TEDREG-1,x
        dex
        bne @tedloop
        rts

tedtbl
        byte $f1,$39            ;0,1:   t1
        byte 0,0                ;2,3:   t2
        byte 0,0                ;4,5:   t3
        byte $1b                ;6:     elm=0, bmm=0, blnk=1, 25 rows, y=3

if PAL = 1
        byte $08                ;7:     rev. video on,pal,freeze=0,mcm=0,40col,x=0
else
        byte $48                ;7:     rev. video on,ntsc,freeze=0,mcm=0,40col,x=0
endif

        byte 0,0                ;8,9:   kbd, int read (don't care)
        byte $02                ;10:    disable all interrupts except raster
        byte $cc                ;11:    raster compare (end of screen)
        byte 0,0                ;12,13: cursor position
        byte 0,0                ;14,15: lsb of sound 1 & 2
        byte 0                  ;16:    msb of sound 2 off
        byte 0                  ;17:    no voice, volume off
        byte $04                ;18:    bm base, charset from rom, ms bits sound 1 off
        byte $d0                ;19:    character base @ $d000, single clock, status
        byte $08                ;20:    vm base @ $c00
        byte $71                ;21:    bkgd 0, ful lum, white
        byte $5b                ;22:    bkgd 1, med lum, lt. red
        byte $75                ;23:    bkgd 2, ful lum, lt. green (not used)
        byte $77                ;24:    bkgd 3, ful lum, yellow (not used)
        byte $6e                ;25:    exterior (ful lum)-1, dk. blue


tedclear        
        ldx #$00
        lda #$20
@clr                    ; clear 40 column screen
        sta $0c00,x
        sta $0d00,x
        sta $0e00,x
        sta $0f00,x
        inx
        bne @clr
        rts



; highlight row stored in a
tedrow_hl
        pha
        clc
        adc #$05 ; add five to row index to skip header rows
        sta $dc ; store selected row

        lda #<$0800
        ldy #>$0800
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


scankey ldy $ff1d ; read keys only once per vertical scan (debounce)
        cpy #$00 ; after waiting, Y reg will be 0 (no key detected yet)
        bne scankey
crsrdn  lda #%11011111  ; activate column 6
        sta $fd30
        sta $ff08
        lda $ff08
        and #%00000001  ; check row 1 (DOWN)
        bne crsrup
        ldy #$01
        jmp keyhndl
crsrup  lda #%11011111  ; activate column 6
        sta $fd30
        sta $ff08
        lda $ff08
        and #%00001000  ; check row 4 (UP)
        bne retchk
        ldy #$02
        jmp keyhndl
retchk  lda #%11111110  ; activate column 1
        sta $fd30
        sta $ff08
        lda $ff08
        and #%00000010  ; check row 2 (RETURN)
        bne keyhndl
        ldy #$03
        jmp keyhndl


keyhndl cpy LASTKEY
        beq keydone     ; same key as last time - do nothing.
godown  cpy #$01
        bne goup
        lda KRNIMG
        cmp #KRNIMGS     ; already at end of list?
        bcs keydone
        beq keydone
        inc KRNIMG
        jsr hilite
goup    cpy #$02
        bne retpush
        lda KRNIMG
        cmp #$01        ; already at beginning of list
        bcc keydone
        beq keydone
        dec KRNIMG
        jsr hilite
retpush cpy #$03
        bne keydone
        jmp sendcmd
keydone sty LASTKEY
        jmp scankey     ; nothing to do now. keep scanning keys
