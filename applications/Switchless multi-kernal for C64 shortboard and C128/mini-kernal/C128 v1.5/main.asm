; Verison history
; 1.0   First version for C128
; 1.1   Added 80 column menu and a sprite on 40 column screen
; 1.2   Cleaned up code. Clear screens to avoid garbage during reset
; 1.4   Added command for C128DCR combo switch. Stepped up version to align version with C64 menu kernal.
; 1.5   Scan keys once per screen refresh to debounce keys

CHARSET   2
NOLOADADDR
GenerateTo c128kernalmenu.bin

incasm constants.asm
incasm macros.asm

KRNIMGS = 4     ; number of kernal images in menu/ROM 1..9 where 1 would be quite pointless :)
                ; It would be possible to have more kernals if menu code is modified.
BODCOL  = $0d   ; border color (C128 default = $0d)
BAKCOL  = $0b   ; background color (C128 default = $0b)
CHRC    = $0d   ; mnutxt color (C128 default = #$0d )
CHRCHL  = $01   ; menu highlightedtext color
VDC_BAKCOL = VDC_DARKWHITE      ; 80-col background color
VDC_CHRC   = VDC_LIGHTBLACK     ; 80-col menu text color
VDC_CHRCHL = VDC_WHITE          ; 80-col highlighted text color

SHIFTS  = $1200 ; 0 = shift not held, 1 = shift held
LASTKEY = $1201 ; last key pressed. used to prevent key repeat
KRNIMG  = $1202
CMDADDR = $1203

*=$c000
  byte $00 ; make file start att c000 to have 16KB size


*=$d000
incbin z80bios.bin ; Z80 BIOS $d000-$dfff


*=$e000
start   
        ldx #$ff        ;normal /reset entry
        sei
        txs
        cld
        jsr mmuinit
        jsr palntsc

        lda #%11100011  ; initialize 6510 port: kybd, cassette, vic control
        sta R6510
        lda #%00101111  ; 6510 ddr
        sta D6510

        jsr vicinit
        ;jsr vicclear

        ; VDC initializtion
        jsr vdcstart    ; initialize VDC registers
        vdcchars chardata, chardata_end ; copy font from kernal ROM to VDC RAM

        lda #VDC_BAKCOL         ; set background color
        ldx #26
        jsr vdcreg_w
        jsr vdcscreenclear      ; clear screen
        
        lda #$00
        tay
        jsr vdcpos_w    ; go to pos 0,0
        vdcmenu mnutxt  ; print menu
        lda #$10
        sta $dc
        lda #$00
        ldy #$08
        jsr vdcpos_w    ; go to pos 0 in attribute memory
attrloop
        ; fill character attribute memory
        lda #VDC_CHRC+VDC_ALTERNATE
        ldy #$ff
        jsr vdcfill
        dec $dc
        bne attrloop


        

        ;setup CIA port data directions
        lda #%11111111 ; all outputs
        sta DDRA             
        lda #%00000000 ; all inputs
        sta DDRB

        lda #$00
        sta SHIFTS      
        sta LASTKEY     
        lda #$01
        sta KRNIMG     ; initial highlighted image = 1


chkcbm  
        ; check for cbm key on start
        lda #%01111111  ; select keyboard row 7
        sta PORTA 
        lda PORTB       ; read keyboard columns
        and #%00100000  ; check for CBM key
        bne not64       ; skip c64 mode
        jmp c64mode
not64   ; continue in C128 mode
        jsr menu
        jsr hilite
        jsr enablesprite0
        jsr scankey


enablesprite0
        ldy #0          ; copy 64 bytes of sprite data to ram
@copy   lda sprite0data,y
        sta $0e00,y
        iny
        cpy #63
        bne @copy
        lda #60
        sta $d000       ; set sprite 0 x pos
        lda #255
        sta $d010       ; enable high byte
        lda #225
        sta $d001       ; set sprite 0 y pos

        lda #160
        lda #CHRC
        sta $d027       ; set sprite 0 color
        lda #%00000001  ; enable sprite 0
        sta $d015
        lda #$38        ; sprite at $0e00        
        sta $07f8        
        rts

disablesprites
        lda #0          ; disable all sprites
        sta $d015
        rts

        ; draw menu on 40 column screen
menu    lda #$17
        sta $d018       ; Switch to lower case chars
        ldy #$00
@drwmnu lda mnutxt,y
        sta $0400,y     ; copy menu chars to screen memory
        lda #CHRC
        sta $d800,y     ; and set char color

        lda mnutxt+256,y
        sta $0500,y
        lda #CHRC
        sta $d900,y

        lda mnutxt+512,y
        sta $0600,y
        lda #CHRC
        sta $da00,y

        lda mnutxt+768,y
        sta $0700,y
        lda #CHRC
        sta $db00,y
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
        jsr vicrow_hl
        jsr vdcrow_hl
        pla
        tay
        pla
        tax
        pla
        rts



scankey lda #$00
        cmp $d012       ; wait for raster line 0 to only scan keys once
        bne scankey     ; per frame to debounce keys 
        sta SHIFTS      ; clear old shift pressed indicators
        tay             ; clear pressed key
        ; find out if any shift key is pressed and set SHIFTS to 1
        ; check for "Right Shift" row 6, column 4
        lda #%10111111  ; select row 6
        sta PORTA 
        lda PORTB       ; read columns
        and #%00010000  ; check against column bit 4
        beq shifted
        ; check for "Left Shift" row 1, column 7
        lda #%11111101  ; select row 1
        sta PORTA 
        lda PORTB       ; read columns
        and #%10000000  ; check against column bit 7
        beq shifted
        jmp crsrchk

shifted lda #$01
        sta SHIFTS

crsrchk ; check for "cursor" row 0, column 7
        lda #%11111110  ; select row 0
        sta PORTA 
        lda PORTB       ; read columns
        and #%10000000  ; check against column bit 7
        bne extchk
        ldx SHIFTS
        cpx #$01
        beq crsrup
        jmp crsrdn

extchk ; check for extended key up
        lda #%11111011  ; select row 2
        sta EXTKB
        lda PORTB       ; read columns
        and #%00001000  ; check against column 3
        beq crsrup
        ; check for extended key down
        lda PORTB       ; read columns
        and #%00010000  ; check against column 4
        beq crsrdn

retchk  ; check for "RETURN" row 0, column bit 1
        lda #%11111110  ; select row 0
        sta PORTA
        lda PORTB       ; read columns
        and #%00000010  ; check against column bit 1
        bne entchk
        ldy #$03
        jmp keyhndl

entchk  ; check for "ENTER" row 0, column bit 1
        lda #%11111101  ; select row 1
        sta EXTKB
        lda PORTB       ; read columns
        and #%00010000  ; check against column bit 4
        bne keyhndl
        ldy #$03
        jmp keyhndl

crsrup  ldy #$02
        jmp keyhndl

crsrdn  ldy #$01
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



sendcmd
        jsr disablesprites
        jsr vicclear
        jsr vdcscreenclear
        ldx #$00
sendasc lda cmdasc,x
        sta CMDADDR,x   ; write command string to data bus to be picked up by kernal switcher
        inx
        cpx #cmdascend-cmdasc   ; length of command string
        bne sendasc
        lda KRNIMG
        sta CMDADDR,x   ; send selected kernal image number to data bus
        ldx #$00
sendascdcr
        lda cmdascdcr,x
        sta CMDADDR,x   ; write command string to data bus to be picked up by kernal switcher
        inx
        cpx #cmdascdcrend-cmdascdcr   ; length of command string
        bne sendascdcr
        lda KRNIMG
        sta CMDADDR,x   ; send selected kernal image number to data bus
        ldx #$00
        jmp sendasc






; ascii RNROM128# command for kernal switcher on data bus
cmdasc ; RNROM128#
  byte $52, $4e, $52, $4f, $4d, $31, $32, $38, $23
cmdascend
; ascii RNROM128DCR# command for C128DCR combo switch
cmdascdcr
        byte $52, $4e, $52, $4f, $4d, $31, $32, $38, $44, $43, $52, $23
cmdascdcrend


mnutxt  ; Menu layout
        ; 6 header rows

        text '                                        '
        text '               RetroNinja               '
        text '                                        '
        text '       C128 Kernal Switcher v1.5        '
        text '                                        '
        text '                                        '
        ; Up to 10 menu choices. number of shown lines controlled by value in $kernalimages
        text '  1. CBM Standard (US)                  '
        text '  2. CBM Standard (Swe/Fin)             '
        text '  3. JiffyDOS 6.02 (US)                 '
        text '  4. JiffyDOS 6.02 (Swe/Fin)            '
        text '                                        '
        text '                                        '
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
        text ' Press RETURN or ENTER to confirm       '
        text '                                        '
        text '                                        '
        text '                                        '



incasm system.asm
incasm vdc.asm
incasm vic.asm

chardata
incbin c128chars.bin
chardata_end

sprite0data
incbin ninjasprite.bin
; TEXT "..................@....."
; TEXT "...@...@.........@@.@..."
; TEXT "..@.@.@..........@.@@..."
; TEXT "...@.@...@@@@@@..@@@...."
; TEXT "....@.@@@@@@@@@@@.@....."
; TEXT "...@.@@@@@@@@@@@@@......"
; TEXT "..@..@@@@@@@@@@@@@@....."
; TEXT ".....@@@@@@@@@@@@@@....."
; TEXT "....@@.....@@.....@@...."
; TEXT "....@..@@......@@..@...."
; TEXT "....@..@@@....@@@..@...."
; TEXT "....@@.....@@.....@@...."
; TEXT "....@@@@@@@@@@@@@@@@...."
; TEXT "....@@@@@@@@@@@@@@@@...."
; TEXT ".....@@@@@@@@@@@@@@....."
; TEXT ".....@@@@@@@@@@@@@@....."
; TEXT "......@@@@@@@@@@@@@....."
; TEXT ".......@@@@@@@@@@@.@...."
; TEXT ".........@@@@@@...@.@..."
; TEXT "...................@.@.."
; TEXT "....................@@.."


*=$fffc ; start vector
        byte <start, >start, <scankey, >scankey
