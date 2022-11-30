; Verison history
; 1.0   First version for C64
; 1.1   Fixed bugs
; 1.2   Improved menu routines and added a sprite
; 1.3   Cleaned up code. Clear screen to avoid garbage during reset
; 1.4   Added command for C128DCR
; 1.5   Scan keys once per screen refresh to debounce keys

CHARSET   2
NOLOADADDR
GenerateTo c64kernalmenu.bin

KRNIMGS = 10    ; number of kernal images in menu/ROM 1..10 where 1 would be quite pointless :)
BODCOL  = $0e   ; border color (C64 default = $0e)
BAKCOL  = $06   ; background color (C64 default = $06)
CHRC    = $0e   ; mnutxt color (C64 default = #$0e )
CHRCHL  = $01   ; menu highlightedtext color

SHIFTS  = $2000 ; 0 = shift not held, 1 = shift held
LASTKEY = $2001 ; last key pressed. used to prevent key repeat
KRNIMG  = $2002
CMDADDR = $2003
VICREG  = $d000
PORTA   = $dc00
PORTB   = $dc01
DDRA    = $dc02
DDRB    = $dc03


*=$e000
start
        sei
        jsr vicinit
        jsr vicclear

        ;setup CIA port data directions
        lda #%11111111 ; all outputs
        sta DDRA             
        lda #%00000000 ; all inputs
        sta DDRB

        lda #$00
        sta SHIFTS      
        sta LASTKEY     
        lda #$01
        sta KRNIMG     ; initial kernal image = 1

        jsr menu
        jsr hilite
        jsr enablesprite0
        jsr scankey


menu    lda #$17
        sta $d018       ; Switch to lower case chars
        ldy #$00
@drwmnu lda mnutxt,y    ; copy menu to screen memory and set char color
        sta $0400,y
        lda #CHRC
        sta $d800,y

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
        pla
        tay
        pla
        tax
        pla
        rts



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



scankey lda #$00
        cmp $d012       ; wait for raster line 0 to only scan keys once
        bne scankey     ; per frame to debounce keys 
        sta SHIFTS      ; clear old shift pressed indicators
        tay             ; clear pressed key
        ; find out if any shift key is pressed and set #$01 at $shiftkey
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
        bne retchk
        ldx SHIFTS
        cpx #$01
        beq crsrup
        jmp crsrdn
retchk  ; check for "RETURN" row 0, column bit 1
        lda #%11111110  ; select row 0
        sta PORTA
        lda PORTB       ; read columns
        and #%00000010  ; check against column bit 1
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


; ascii RNROM64# command for kernal switcher on data bus
cmdasc  byte $52, $4e, $52, $4f, $4d, $36, $34, $23
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
        text '        C64 Kernal Switcher v1.5        '
        text '                                        '
        text '                                        '
        ; Up to 10 menu choices. number of shown lines controlled by value in $kernalimages
        text '  1. CBM Standard (US)                  '
        text '  2. CBM Standard (Swe/Fin)             '
        text '  3. JiffyDOS 6.01 (US)                 '
        text '  4. JiffyDOS 6.01 (Swe/Fin)            '
        text '  5. JaffyDOS 1.3 (US)                  '
        text '  6. JaffyDOS 1.3 (Swe/Fin)             '
        text '  7. DolphinDOS 3.0 (US)                '
        text '  8. DolphinDOS 3.0 (Swe)               '
        text '  9. SpeedDOS Plus (US)                 '
        text ' 10. SpeedDOS Plus (Swe)                '
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

incasm vic.asm

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
