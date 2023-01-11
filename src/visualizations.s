.include "x16.inc"

.import ymnote, yminst, ymmidi, midibend
.export do_midi_sprites
.export setup_sprites

.segment "BSS"

iterator:
    .res 1
tmp1:
    .res 1
tmp2:
    .res 1
pitchdown:
    .res 1


.segment "CODE"

.proc do_midi_sprites: near
    stz iterator

    stz Vera::Reg::Ctrl
    lda #<Vera::VRAM_sprattr
    sta Vera::Reg::AddrL
    lda #>Vera::VRAM_sprattr
    sta Vera::Reg::AddrM
    lda #^Vera::VRAM_sprattr
    ora #$10 ; auto increment = 1
    sta Vera::Reg::AddrH

    ldx iterator
sploop:
    lda ymnote,x
    bne :+
    jmp hideit
:

    lda ymmidi,x
    tay

    stz pitchdown
    lda yminst,x
    lsr
    lsr
    lsr
    lsr
    inc
    cmp #$10
    bne :+
    lda #1
:
    asl
    asl

    sta tmp1
    stz tmp2

    lda midibend,y
    beq endbend

    bpl contbend

    ldy #2
    sty pitchdown

    cmp #$C0
    bcc hardbend
    bra softbend
contbend:
    cmp #$40
    bcs hardbend
softbend:
    lda tmp1
    clc
    adc #64
    sta tmp1
    lda #0
    adc #0
    sta tmp2
    bra endbend
hardbend:
    lda tmp1
    clc
    adc #128
    sta tmp1
    lda #0
    adc #0
    sta tmp2
endbend:
    lda tmp1
    sta Vera::Reg::Data0

    ; no high bits, mode 0
    lda tmp2
    sta Vera::Reg::Data0

    ; multiply MIDI channel by 16
    lda ymmidi,x
    asl
    asl
    asl
    asl
    
    ; add #320 and drop the X
    clc
    adc #<(320)
    sta Vera::Reg::Data0
    lda #>(320)
    adc #0
    sta Vera::Reg::Data0

    ; note is Y
    lda #255
    sec
    sbc ymnote,x
    sbc ymnote,x

    ; bring it downward on the screen by 128
    clc
    adc #128
    sta Vera::Reg::Data0

    lda #0
    adc #0
    sta Vera::Reg::Data0

    ; set the Z depth
    lda #$0C
    ora pitchdown
    sta Vera::Reg::Data0

    ; set 16x16
    lda #$50
    sta Vera::Reg::Data0
    bra splend
    

hideit:
    stz Vera::Reg::Data0
    stz Vera::Reg::Data0
    stz Vera::Reg::Data0
    stz Vera::Reg::Data0
    stz Vera::Reg::Data0
    stz Vera::Reg::Data0
    stz Vera::Reg::Data0
    stz Vera::Reg::Data0
splend:
    inc iterator
    ldx iterator
    cpx #8
    bcs end
    jmp sploop

end:
    rts
.endproc


.proc setup_sprites: near
    ; Create 16x16 4bpp sprite data, all starting at $00000

    stz Vera::Reg::Ctrl
    stz Vera::Reg::AddrL
    stz Vera::Reg::AddrM
    lda #$10 ; auto increment = 1
    sta Vera::Reg::AddrH

    ; First sprite is gonna be for the "note blocked" sprite
    ldx #0
:
    lda note_blocked,x
    sta Vera::Reg::Data0
    inx
    bpl :- ; 128 of them

    ; These next 15 are gonna be straight lines in various indexes
    lda #$11
    sta iterator
lineloop:    
    
    ldx #0
:
    lda note,x
    and iterator
    sta Vera::Reg::Data0
    inx
    bpl :- ; 128
    
    lda iterator
    clc
    adc #$11
    sta iterator
    cmp #$10 ; first overflow should land here
    bne lineloop

; blank sprite
    ldx #0
:
    lda note_blocked,x
    sta Vera::Reg::Data0
    inx
    bpl :- ; 128 of them


; now do pitch bendy things
    lda #$11
    sta iterator
bendloop1:
    
    ldx #0
:
    lda bend_1,x
    and iterator
    sta Vera::Reg::Data0
    inx
    bpl :- ; 128

    lda iterator
    clc
    adc #$11
    sta iterator
    cmp #$10 ; first overflow should land here
    bne bendloop1


    lda #$11
    sta iterator

; blank sprite
    ldx #0
:
    lda note_blocked,x
    sta Vera::Reg::Data0
    inx
    bpl :- ; 128 of them


bendloop2:
    
    ldx #0
:
    lda bend_2,x
    and iterator
    sta Vera::Reg::Data0
    inx
    bpl :- ; 128

    lda iterator
    clc
    adc #$11
    sta iterator
    cmp #$10 ; first overflow should land here
    bne bendloop2


    ; enable sprites
    lda Vera::Reg::DCVideo
    ora #$40
    sta Vera::Reg::DCVideo

    rts

bend_1:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$FF,$FF,$FF,$FF,$00,$00
    .byte $0F,$FF,$FF,$00,$00,$FF,$FF,$F0
    .byte $FF,$F0,$00,$00,$00,$00,$0F,$FF
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

bend_2:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$0F,$F0,$00,$00,$00
    .byte $00,$00,$00,$FF,$FF,$00,$00,$00
    .byte $00,$00,$0F,$F0,$0F,$F0,$00,$00
    .byte $00,$FF,$FF,$00,$00,$FF,$FF,$00
    .byte $FF,$F0,$F0,$00,$00,$0F,$0F,$FF
    .byte $FF,$00,$00,$00,$00,$00,$0F,$FF
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

note:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

note_blocked:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$01,$11,$11,$11,$00,$00
    .byte $00,$00,$11,$11,$11,$11,$10,$00 
    .byte $00,$01,$11,$00,$00,$01,$11,$00 
    .byte $00,$11,$10,$00,$00,$01,$11,$10
    .byte $01,$11,$00,$00,$00,$11,$11,$11 
    .byte $01,$10,$00,$00,$01,$11,$00,$11
    .byte $01,$10,$00,$00,$11,$10,$00,$11
    .byte $01,$10,$00,$01,$11,$00,$00,$11 
    .byte $01,$10,$00,$11,$10,$00,$00,$11 
    .byte $01,$10,$01,$11,$00,$00,$00,$11
    .byte $01,$11,$11,$10,$00,$00,$01,$11
    .byte $00,$11,$11,$00,$00,$00,$11,$10
    .byte $00,$01,$11,$00,$00,$01,$11,$00
    .byte $00,$00,$11,$11,$11,$11,$10,$00
    .byte $00,$00,$01,$11,$11,$11,$00,$00

.endproc