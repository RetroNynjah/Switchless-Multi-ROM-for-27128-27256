; Setup default MMU registers
mmuinit
        lda #0
        sta MMUCR       ; configure system map: c/128 mode, i/o in, ram0 
        ldx #10
mmuloop lda mmutbl,x
        sta MMU_LO,x    ; reset all mmu registers
        dex
        bpl mmuloop
        rts

mmutbl  byte $00,$00,$00,$00,$00,$bf,$04,$00,$00,$01,$00



; Detect PAL or NTSC
; $0a03: $0 = NTSC, $ff = PAL
palntsc
        ldx #$ff        ;setup for PAL/NTSC test
@10     lda VICREG+17
        bpl @10         ;...branch until raster at bottom
@20     lda #$08
        cmp VICREG+18
        bcc @30         ;...branch if >264: PAL system
        lda VICREG+17
        bmi @20         ;...branch until raster wraps to top
        inx             ;NTSC system
@30     stx PALNTS
        rts


; Switch to c64 mode
c64mode 
        lda #%11100011  ; initialize 6510 port
        sta R6510
        lda #%00101111  ; 6510 ddr
        sta D6510
        ldx #c64end-c64beg
dlcode  lda c64beg-1,x  ; download 64 mode code to RAM
        sta BANK-1,x
        dex
        bne dlcode
        stx VICREG+48   ; force 1MHz mode
c64beg  lda #$f7        ; 64 mode code
        sta MMUCR
        jmp ($fffc)
c64end


