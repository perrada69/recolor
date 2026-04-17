; =============================================================================
; RECOLOR - ZX Spectrum Next dot command
; Loads a .NXP palette (512 B) and uploads it to ULA first palette.
; Uses classic ULA colour semantics (INK/PAPER/BORDER), not ULANext mode.
; =============================================================================

    ORG $2000

NEXTREG_SEL      EQU $243B
NEXTREG_DAT      EQU $253B

NR_PALETTE_IDX   EQU $40
NR_PALETTE_VAL   EQU $41
NR_PALETTE_CTRL  EQU $43
NR_PALETTE_VAL9  EQU $44
NR_ULA_CTRL      EQU $68     ; bit 3 = enhanced ULA palette enable

PALCTRL_ULA_1    EQU %00000000   ; ULA first palette for read/write, auto-inc on

F_OPEN           EQU $9A
F_CLOSE          EQU $9B
F_READ           EQU $9D
FA_READ          EQU $01

SIZE_PALETTE     EQU 512

MAIN:
    di
    ld      (arg_ptr), hl

    ld      hl, (arg_ptr)
    call    EXTRACT_FILENAME
    jp      c, SHOW_HELP

    ld      a, (filename_buf)
    or      a
    jp      z, SHOW_HELP
    cp      13
    jp      z, SHOW_HELP

    cp      '-'
    jr      nz, MAIN_NOT_HELP
    ld      a, (filename_buf+1)
    and     $DF
    cp      'H'
    jp      z, SHOW_HELP
MAIN_NOT_HELP:

    ld      hl, filename_buf
    ld      a, '*'
    ld      b, FA_READ
    rst     $08
    defb    F_OPEN
    jp      c, ERR_OPEN

    ld      (file_handle), a

    ld      a, (file_handle)
    ld      hl, palette_buf
    ld      bc, SIZE_PALETTE
    rst     $08
    defb    F_READ
    jp      c, ERR_READ

    ; BC = bytes actually read, must be exactly 512 = $0200
    ld      a, b
    cp      2
    jp      nz, ERR_SIZE
    ld      a, c
    or      a
    jp      nz, ERR_SIZE

    ld      a, (file_handle)
    rst     $08
    defb    F_CLOSE

    call    UPLOAD_PALETTE_ULA

    ei
    ld      hl, msg_ok
    call    PRINT_MSG
    ld      hl, filename_buf
    call    PRINT_ASCIIZ_SAFE
    call    PRINT_NL
    ld      bc, 0
    ret

ERR_OPEN:
    push    af
    ld      hl, msg_err_open
    call    PRINT_MSG
    ld      hl, filename_buf
    call    PRINT_ASCIIZ_SAFE
    call    PRINT_NL
    ld      hl, msg_errcode
    call    PRINT_MSG
    pop     af
    call    PRINT_HEX8
    call    PRINT_NL
    call    DECODE_ERRCODE
    ld      bc, 0
    ret

ERR_READ:
    push    af
    ld      a, (file_handle)
    rst     $08
    defb    F_CLOSE
    ld      hl, msg_err_read
    call    PRINT_MSG
    pop     af
    call    PRINT_HEX8
    call    PRINT_NL
    ld      bc, 0
    ret

ERR_SIZE:
    ld      a, (file_handle)
    rst     $08
    defb    F_CLOSE
    ld      hl, msg_err_size
    call    PRINT_MSG
    ld      bc, 0
    ret

; =============================================================================
; UPLOAD_PALETTE_ULA
; Upload full 9-bit palette from NXP:
;   bytes   0..255   palLo (RRRGGGBB)
;   bytes 256..511   palHi (bit0 = blue LSB)
; NOTE: the previous broken build used B as a 256-loop counter and at the same
; time as the high byte of port BC, so OUTs went to the wrong ports.
; =============================================================================
UPLOAD_PALETTE_ULA:
    ; select ULA first palette with auto-increment
    ld      bc, NEXTREG_SEL
    ld      a, NR_PALETTE_CTRL
    out     (c), a
    ld      bc, NEXTREG_DAT
    ld      a, PALCTRL_ULA_1
    out     (c), a

    ; index = 0
    ld      bc, NEXTREG_SEL
    ld      a, NR_PALETTE_IDX
    out     (c), a
    ld      bc, NEXTREG_DAT
    xor     a
    out     (c), a

    ld      hl, palette_buf            ; palLo[0]
    ld      de, palette_buf+256        ; palHi[0]
    xor     a                          ; 256-iteration counter via wraparound

UPLOAD_LOOP:
    push    af

    ; write first byte of 9-bit colour to $44
    ld      bc, NEXTREG_SEL
    ld      a, NR_PALETTE_VAL9
    out     (c), a
    ld      bc, NEXTREG_DAT
    ld      a, (hl)
    inc     hl
    out     (c), a

    ; write second byte of 9-bit colour to $44 (bit0 = blue LSB)
    ld      a, (de)
    inc     de
    and     1
    out     (c), a

    pop     af
    inc     a
    jr      nz, UPLOAD_LOOP
    ret

EXTRACT_FILENAME:
    ld      de, filename_buf
    ld      b, 63

EXTRACT_SKIP:
    ld      a, (hl)
    or      a
    jr      z, EXTRACT_EMPTY
    cp      $0D
    jr      z, EXTRACT_EMPTY
    cp      ' '
    jr      z, EXTRACT_NEXT
    cp      $0E
    jr      nz, EXTRACT_CHK_TOK
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    jr      EXTRACT_SKIP

EXTRACT_CHK_TOK:
    cp      $A5
    jr      nc, EXTRACT_NEXT
    jr      EXTRACT_FIRST_CHAR

EXTRACT_NEXT:
    inc     hl
    jr      EXTRACT_SKIP

EXTRACT_EMPTY:
    scf
    ret

EXTRACT_FIRST_CHAR:
    cp      '"'
    jr      z, EXTRACT_QUOTED

EXTRACT_PLAIN:
    ld      a, (hl)
    or      a
    jr      z, EXTRACT_DONE
    cp      $0D
    jr      z, EXTRACT_DONE
    cp      ' '
    jr      z, EXTRACT_DONE
    cp      $A5
    jr      nc, EXTRACT_DONE
    cp      $20
    jr      c, EXTRACT_PLAIN_SKIP
    ld      (de), a
    inc     de
    dec     b
    jr      z, EXTRACT_DONE
EXTRACT_PLAIN_SKIP:
    inc     hl
    jr      EXTRACT_PLAIN

EXTRACT_QUOTED:
    inc     hl
EXTRACT_QLOOP:
    ld      a, (hl)
    or      a
    jr      z, EXTRACT_DONE
    cp      $0D
    jr      z, EXTRACT_DONE
    cp      '"'
    jr      z, EXTRACT_DONE
    ld      (de), a
    inc     de
    inc     hl
    dec     b
    jr      nz, EXTRACT_QLOOP

EXTRACT_DONE:
    xor     a
    ld      (de), a
    or      a
    ret

SHOW_HELP:
    ld      hl, msg_help
    call    PRINT_MSG
    ld      bc, 0
    ret

DECODE_ERRCODE:
    push    af
    ld      hl, msg_err_prefix
    call    PRINT_MSG
    pop     af
    cp      2
    jr      z, ERR_E2
    cp      3
    jr      z, ERR_E3
    cp      5
    jr      z, ERR_E5
    cp      7
    jr      z, ERR_E7
    cp      8
    jr      z, ERR_E8
    ld      hl, msg_eunk
    call    PRINT_MSG
    ret

ERR_E2:
    ld      hl, msg_e2
    call    PRINT_MSG
    ret
ERR_E3:
    ld      hl, msg_e3
    call    PRINT_MSG
    ret
ERR_E5:
    ld      hl, msg_e5
    call    PRINT_MSG
    ret
ERR_E7:
    ld      hl, msg_e7
    call    PRINT_MSG
    ret
ERR_E8:
    ld      hl, msg_e8
    call    PRINT_MSG
    ret

PRINT_MSG:
    ld      a, (hl)
    or      a
    ret     z
    rst     $10
    inc     hl
    jr      PRINT_MSG

PRINT_NL:
    ld      a, 13
    rst     $10
    ret

PRINT_HEX8:
    push    af
    rrca
    rrca
    rrca
    rrca
    call    PRINT_HEX8_NIB
    pop     af
PRINT_HEX8_NIB:
    and     $0F
    add     a, '0'
    cp      '9'+1
    jr      c, PRINT_HEX8_OK
    add     a, 7
PRINT_HEX8_OK:
    rst     $10
    ret

PRINT_ASCIIZ_SAFE:
    ld      b, 40
PRINT_ASCIIZ_SAFE_LOOP:
    ld      a, (hl)
    or      a
    ret     z
    cp      13
    ret     z
    rst     $10
    inc     hl
    djnz    PRINT_ASCIIZ_SAFE_LOOP
    ret

arg_ptr:        defw    0
file_handle:    defb    0

msg_errcode:    defm    " ErrCode=", 0
msg_err_prefix: defm    "esxDOS: ", 0
msg_e2:         defm    "File not found", 13, 0
msg_e3:         defm    "Path not found", 13, 0
msg_e5:         defm    "Access denied", 13, 0
msg_e7:         defm    "Invalid filename", 13, 0
msg_e8:         defm    "Invalid drive", 13, 0
msg_eunk:       defm    "Unknown error", 13, 0
msg_err_open:   defm    "Cannot open: ", 0
msg_err_read:   defm    "Read error: $", 0
msg_err_size:   defm    "Bad NXP size (need 512 B)", 13, 0
msg_ok:         defm    "ULA palette loaded: ", 0

msg_help:
    defm    "RECOLOR 1.1 - ULA palette loader", 13
    defm    "Shrek/MB Maniax, 2026", 13
    defm    "Idea: Bernhard (Luzie67)", 13
    defb    13
    defm    "Loads a 512 B .NXP palette into", 13
    defm    "the ULA first palette.", 13
    defm    "INK/PAPER/BORDER update at once.", 13
    defb    13
    defm    "Usage:", 13
    defm    "  .recolor file.nxp", 13
    defm    "  .recolor ", 34, "my palette.nxp", 34, 13
    defm    "  .recolor -h", 13
    defb    13
    defm    "NXP format:", 13
    defm    "  512 B binary", 13
    defm    "  0..255   palLo RRRGGGBB", 13
    defm    "  256..511 palHi bit0 = blue LSB", 13
    defb    0

filename_buf:   defs    64, 0
palette_buf:    defs    512, 0

    END     MAIN
