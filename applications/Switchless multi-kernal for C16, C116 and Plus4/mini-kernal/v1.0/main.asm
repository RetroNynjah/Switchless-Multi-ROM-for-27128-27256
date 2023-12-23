; Verison history
; 1.0   First version for Plus/4
PAL = 0         ; PAL = 0 for NTSC
CHARSET   2
NOLOADADDR


if PAL = 1
GenerateTo plus4kernalmenu_pal.bin
else
GenerateTo plus4kernalmenu_ntsc.bin
endif

PDIR = $00      ;7501 port data dir reg
PORT = $01      ;7501 internal i/o port

KRNIMGS = 6     ; number of kernal images in menu/ROM 1..10 where 1 would be quite pointless :)
BODCOL  = $6e   ; border color (Plus/4 default = $6e)
BAKCOL  = $71   ; background color (Plus/4 default = $71)
CHRC    = $10   ; mnutxt color (Plus/4 default = #$10 )
CHRCHL  = $46   ; menu highlightedtext color

SHIFTS  = $4000 ; 0 = shift not held, 1 = shift held
LASTKEY = $4001 ; last key pressed. used to prevent key repeat
KRNIMG  = $4002
CMDADDR = $4003
TEDREG  = $ff00


* = $c000
if PAL = 1
        ;text "PAL"
        byte $50, $41, $4c
else
        ;text "NTSC"
        byte $4e,$54,$53,$43
endif

* = $d000
incbin plus4chars.bin

* = $d800
start
        sei
        jsr tedinit
        jsr tedclear

        lda #$00
        sta SHIFTS      
        sta LASTKEY     
        lda #$01
        sta KRNIMG     ; initial kernal image = 1

        jsr menu
        jsr hilite
        jsr scankey

menu    lda $ff13
        ora #%00000100
        sta $ff13       ; Switch to lower case chars
        lda #$ff
        sta $ff0d       ; Hide curose
        lda $ff0c
        ora #%00000011
        sta $ff0c       ; Hide cursor
        ldy #$00
@drwmnu lda mnutxt,y    ; copy menu to screen memory and set char color
        sta $0c00,y
        lda #CHRC
        sta $0800,y

        lda mnutxt+256,y
        sta $0d00,y
        lda #CHRC
        sta $0900,y

        lda mnutxt+512,y
        sta $0e00,y
        lda #CHRC
        sta $0a00,y

        lda mnutxt+768,y
        sta $0f00,y
        lda #CHRC
        sta $0b00,y
        iny
        bne @drwmnu
        rts

hilite 
        pha
        txa
        pha
        tya
        pha
        lda KRNIMG
        jsr tedrow_hl
        pla
        tay
        pla
        tax
        pla
        rts



sendcmd
        jsr tedclear
        ldx #$00
sendasc lda cmdasc,x
        sta CMDADDR,x   ; write command string to data bus to be picked up by kernal switcher
        inx
        cpx #cmdascend-cmdasc   ; length of command string
        bne sendasc
        lda KRNIMG
        sta CMDADDR,x   ; send selected kernal image number to data bus
        jmp sendcmd

cmdasc  byte $52, $4e, $52, $4f, $4d, $2b, $34, $23     ; ascii RNROM+4# command for kernal switcher on address bus
cmdascend


mnutxt  ; Menu layout
        ; 6 header rows
        text '                                        '
        text '               RetroNinja               '
        text '                                        '
        text '      Plus/4 Kernal Switcher v1.0       '
        text '                                        '
        text '                                        '
        ; Up to 10 menu choices. number of shown lines controlled by value in $kernalimages
        text '  1. CBM Standard (US)                  '
        text '  2. CBM Standard (Swe/Fin)             '
        text '  3. JiffyDOS 6.01 (US)                 '
        text '  4. JiffyDOS 6.01 (Swe/Fin)            '
        text '  5. 6510 Adapter Kernal (US)           '
        text '  6. 6510 Adapter Kernal (Swe/Fin)      '
        text '                                        '
        text '                                        '
        text '                                        '
        text '                                        '
        ; 8 footer rows
        text '                                        '
        text '                                        '
        text '                                        '
        text ' Use cursor up/down to select a kernal  '
        text '                                        '
        text ' Press RETURN to confirm                '
        text '                                        '
        text '                                        '
        text '                                        '

incasm ted.asm

*=$fffc ; start vector
        byte <start, >start, <scankey, >scankey
