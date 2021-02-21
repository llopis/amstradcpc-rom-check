DetectROMs:
	ld hl,TxtDetecting
	call PrintString
	call NewLine
	
	call CheckLowerROM
	
	ld d,0
	push de
_detectROMsLoop:
	call CheckUpperROM
	pop de	
	inc d
	push de
	ld a,d
	cp #0F
	jr nz,_detectROMsLoop
	pop de

	call NewLine
	
	ret
	

TxtDetecting: db 'DETECTING ROMs...',0
TxtLowerROM: db 'LOWER ROM: ',0
TxtROM: db 'ROM ',0
TxtColon: db ': ',0


CheckLowerROM:
	ld hl,TxtLowerROM
	call PrintString

	call CRCLowerRom
	push hl
	call PrintROMName
	ld a,CharSpace
	call PrintChar
	ld a,CharLeftParen
	call PrintChar
	pop hl
	ld a,h
	call PrintNumHex
	ld a,l
	call PrintNumHex
	ld a,CharRightParen
	call PrintChar
	call NewLine
	ret


CRCLowerRom:
	di
	ld bc,#7F89                        ; GA select lower rom, and mode 1
	out (c),c

	ld ix,#0000
	ld de,#4000	
	call Crc16
	
	ld bc,#7F8D                        ; GA deselect lower rom, and mode 1
	out (c),c
	ei
	
	ret


; IN D = ROM to check
CheckUpperROM:
	ld a,d
	call GetUpperROMType
	
	; Skip any roms of type #80 that are not the 0 ROM
	cp #80
	jr nz,_checkUpperROMDoIt
	ld a,d
	or a
	jr z,_checkUpperROMDoIt
	ret
	
_checkUpperROMDoIt:
	ld hl,TxtROM
	call PrintString
	ld a,d
	call PrintNumHex
	ld hl,TxtColon
	call PrintString	
	ld a,d
	call CRCRom
	push hl
	call PrintROMName

	ld a,CharSpace
	call PrintChar
	ld a,CharLeftParen
	call PrintChar
	pop hl
	ld a,h
	call PrintNumHex
	ld a,l
	call PrintNumHex
	ld a,CharRightParen
	call PrintChar
	call NewLine
	ret


; IN A = ROM number to read
; OUT A = ROM Type
GetUpperROMType:
	di
	ld bc,#7F85                        ; GA select upper rom, and mode 1
	out (c),c

	ld bc,#df00
	out (c),a
	
	ld a,(#C000)
	
	ld bc,#7F8D                        ; GA deselect upper rom, and mode 1
	out (c),c
	ei
	
	ret

; IN A = ROM number to read
; OUT HL = CRC
;     A = ROM Type
CRCRom:
	di
	ld bc,#7F85                        ; GA select upper rom, and mode 1
	out (c),c

	ld bc,#df00
	out (c),a
	
	ld ix,#C000
	ld de,#4000	
	call Crc16
	
	ld a,(#C000)
	
	ld bc,#7F8D                        ; GA deselect upper rom, and mode 1
	out (c),c
	ei
	
	ret


; IN IX = Start address DE = Size
; OUT HL = CRC
; Based on code from from http //map.tni.nl/sources/external/z80bits.html#5.1
Crc16:
	ld hl,#FFFF
_crc16Read:
	ld	a,(ix)
	inc	ix
	xor	h
	ld	h,a
	ld	b,8
_crc16CrcByte:
	add	hl,hl
	jr	nc,_crc16Next
	ld	a,h
	xor	#10
	ld	h,a
	ld	a,l
	xor	#21
	ld	l,a
_crc16Next:
	djnz _crc16CrcByte
	dec de
	ld a,e
	or d
	jr nz,_crc16Read	
	ret


ROMCount equ 12

TxtUnknownROM: db 'UNKNOWN ROM',0
TxtBASIC10EN: db 'BASIC 1.0 EN',0
TxtBASIC11EN: db 'BASIC 1.1 EN',0
TxtBASIC11SP: db 'BASIC 1.1 SP',0
TxtBASIC11FR: db 'BASIC 1.1 FR',0
TxtAMSDOS: db 'AMSDOS',0
TxtPARADOS: db 'PARADOS',0
TxtOS464EN: db 'OS 464 EN',0
TxtOS464SP: db 'OS 464 SP',0
TxtOS464FR: db 'OS 464 FR',0
TxtOS6128EN: db 'OS 6128 EN',0
TxtOS6128SP: db 'OS 6128 SP',0
TxtOS6128FR: db 'OS 6128 FR',0

ROMInfoTable:
	defw #6098, TxtBASIC10EN
	defw #CAA0, TxtBASIC11EN
	defw #03E4, TxtBASIC11SP
	defw #814D, TxtBASIC11FR
	defw #0F91, TxtAMSDOS
	defw #D75F, TxtPARADOS
	defw #5D07, TxtOS464EN
	defw #3E84, TxtOS464SP
	defw #0EEA, TxtOS464FR
	defw #B360, TxtOS6128EN
	defw #BAF7, TxtOS6128SP
	defw #8051, TxtOS6128FR


; IN HL = CRC
PrintROMName:
	ld b,ROMCount
	ld ix,ROMInfoTable
	
_printROMNameLoop:
	ld e,(ix)
	ld d,(ix+1)
	ld a,e
	ld a,l
	cp e
	jr nz, _printROMNameNext

	ld a,d
	ld a,h
	cp d
	jr nz, _printROMNameNext
	ld l,(ix+2)
	ld h,(ix+3)
	call PrintString
	ret
	
_printROMNameNext:
	inc ix
	inc ix
	inc ix
	inc ix
	djnz _printROMNameLoop
	
	ld hl,TxtUnknownROM
	call PrintString
	ret
	