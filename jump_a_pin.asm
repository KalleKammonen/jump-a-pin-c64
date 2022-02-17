// 1.2:
// Makes a .d64 file.
// TODO:
// Better graphics
// Joystick (keyboard arrows) cursor movement
// Custom characters (a,b,c) - problem
// Music
// Better intro screen

.import source "constants.asm"
.import source "vic2constants.asm"

.const jump_length = $18 //24
.const hole = 0    //0
.const peg = 1        //1
.const no_hole = 2       //2
.const char_gap = 3
.const board_screenstart = 1868

.var state_mem = $C000
.var spr0_ind = $C050
.var move_from = $C060
.var move_to = $C061
.var move_distance = $C062
.var move_in_between = $C063
.var move_holder = $C064
.var key_input = $C070
.var quit_game = $C071
.var char_offset = $C072
.var pl1_score = $C073
.var pl2_score = $C074
.var player = $C075
.var action = $C076             // 1:up, 2:down, 3:left, 4:right, 5:Pl1-from, 6:Pl2-from, 7:To, 8:Move (Disabled)

BasicUpstart2(boardinit)
// Create the D64 image
.disk [filename="jap.d64", name="JUMPAPIN", id=" 12"]
{
  [name="JUMPAPIN", type="prg", segments="Default"]
}

*=$1000
spr0_hpos:
.byte 00
spr0_vpos:
.byte 00
spr0_pos:
.byte 00
introtext:
.text "jump-a-pin"
.byte 0
press_keytext:
.text "press any key to start"
.byte 0
player1_text:
.text "pl1"
.byte 0
player2_text:
.text "pl2"
.byte 0

boardinit:
//path
        lda #0
        sta move_from
        sta move_to
        sta move_distance
        sta move_in_between
        sta move_holder
// Row 7
        lda #no_hole
        sta state_mem+42
        sta state_mem+43
        sta state_mem+47
        sta state_mem+48
        lda #peg
        sta state_mem+44
        sta state_mem+45
        sta state_mem+46
// Row 6
        lda #no_hole
        sta state_mem+35
        sta state_mem+41
        lda #peg
        sta state_mem+36
        sta state_mem+37
        sta state_mem+38
        sta state_mem+39
        sta state_mem+40
// Row 5
        lda #peg
        sta state_mem+28
        sta state_mem+29
        sta state_mem+30
        sta state_mem+31
        sta state_mem+32
        sta state_mem+33
        sta state_mem+34
// Row 4
        lda #peg
        sta state_mem+21
        sta state_mem+22
        sta state_mem+23
        sta state_mem+25
        sta state_mem+26
        sta state_mem+27
        lda #hole
        sta state_mem+24
// Row 3
        lda #peg
        sta state_mem+14
        sta state_mem+15
        sta state_mem+16
        sta state_mem+17
        sta state_mem+18
        sta state_mem+19
        sta state_mem+20
// Row 2
        lda #no_hole
        sta state_mem+7
        sta state_mem+13
        lda #peg
        sta state_mem+8
        sta state_mem+9
        sta state_mem+10
        sta state_mem+11
        sta state_mem+12
// Row 1
        lda #no_hole
        sta state_mem
        sta state_mem+1
        sta state_mem+5
        sta state_mem+6
        lda #peg
        sta state_mem+2
        sta state_mem+3
        sta state_mem+4
gameinit:
        lda #0
        sta quit_game
        sta move_distance
        sta move_from
        sta move_holder
        sta move_in_between
        sta move_to
        sta pl1_score
        sta pl2_score
        lda #1
        sta player
gametitle:
// Make character ROM visible at $D000-$DFFF
        sei             // Disable interrupts
        lda 1        
        and #251        // Change third bit to 0, 11111011
        sta 1
        ldx #24          // Start from character
// Copy characters from ROM
char_init_loop:
        lda VIC_BASE,x
        sta $3000,x
        lda VIC_BASE+256,x
        sta $3100,x
        inx
        bne char_init_loop      // Loop until hitting 0 again
// Turn off character ROM visibility
        lda 1
        ora #4
        sta 1
        cli
        ldx #0
//Enable multicolour mode
//        lda VIC_CONTR_REG
//        ora #16
//        sta VIC_CONTR_REG
//        cli
        lda #black
        sta BORDER_COLOR
        sta SCREEN_COLOR
        lda #lblue
        sta TEXT_COLOR
        // lda #yellow
        // sta TXT_COLOUR_1
        // lda #grey
        // sta TXT_COLOUR_2
        jsr CLS
        ldx #$0
introloop:
        lda introtext,x
        beq nexttext
        sta SCREEN_MEM+15,x
        inx
        jmp introloop
nexttext:
        ldx #$0
presskeyloop:
        lda press_keytext,x
        beq keyloop_start
        sta SCREEN_MEM+889,x
        inx
        jmp presskeyloop
keyloop_start:
        jsr CHR_IN
        beq keyloop_start       //Loop if no key is pressed
gamestart:
//Point char bank at $3000
        lda GRAPHICS_POINTER
        and #240
        clc 
        adc #12
        sta GRAPHICS_POINTER

    lda #215 //13760
    sta SPRITE_POINTER_0
    lda #216
    sta SPRITE_POINTER_1
    lda #217
    sta SPRITE_POINTER_2
    lda #red
    sta SPRITE_MULTICOLOR_3_0
    lda #120 //start pos
    sta SPRITE_0_X
    lda #140 //start pos
    sta SPRITE_0_Y
    lda #%00000000 //0=hires sprite
    sta SPRITE_HIRES

    lda #%00000000 //double size
    sta SPRITE_DOUBLE_X
    sta SPRITE_DOUBLE_Y

    lda #%00000111
    sta SPRITE_ENABLE

    clc
    lda spr0_hpos
    adc #4 //start pos hor
    sta spr0_hpos
    lda spr0_vpos
    adc #4 //start pos ver
    sta spr0_vpos
    lda spr0_pos
    adc #44 //start pos
    sta spr0_pos

    lda #$00
    sta spr0_ind
    lda spr0_ind
    adc #24 //start index
    sta spr0_ind
        lda #147        // CLR HOME.
        jsr CHR_OUT     // Print.
        ldx #0
pl1textloop:
        lda player1_text,x
        beq pl1textloopdone
        sta SCREEN_MEM+7,x
//        lda #white
//        sta COLOUR_MEM+7,x
        inx
        jmp pl1textloop
pl1textloopdone:
        ldx #0
pl2textloop:
        lda player2_text,x
        beq gamestart_cont
        sta SCREEN_MEM+32,x
//        lda #white
//        sta COLOUR_MEM+32,x
        inx
        jmp pl2textloop
gamestart_cont:
    jsr print_status
    jsr print_cords
    jsr print_board
    jsr gameloop
    rts
gameloop:
        jsr input
        jsr process
        jsr output
        jmp gameloop
input:
keyloop:
        jsr CHR_IN
        beq keyloop
        sta key_input
reset_action:
        lda #0
        sta action
cursor_up:
        lda key_input
        cmp #$57        // w - up
        bne cursor_down
        // Check position
        lda spr0_ind
        cmp #28
        beq cursor_up_return
        cmp #34
        beq cursor_up_return
        cmp #36
        beq cursor_up_return
        cmp #40
        beq cursor_up_return
        lda spr0_vpos
        cmp #7
        bcs cursor_up_return
        // Action is OK
        lda #1          // 1 - Up
        sta action
cursor_up_return:
        rts
cursor_down:
        lda key_input
        cmp #$53        // s - Down
        bne cursor_left
        //Check position
        lda spr0_ind
        cmp #8
        beq cursor_down_return
        cmp #12
        beq cursor_down_return
        cmp #14
        beq cursor_down_return
        cmp #20
        beq cursor_down_return
        lda spr0_vpos
        cmp #2
        bcc cursor_down_return
        // Action is OK
        lda #2          // 2 - Down
        sta action
cursor_down_return:
        rts
cursor_left:
        lda key_input
        cmp #$41                // a - Left
        bne cursor_right
        //Check position
        lda spr0_ind
        cmp #2
        beq cursor_left_return
        cmp #8
        beq cursor_left_return
        cmp #36
        beq cursor_left_return
        cmp #44
        beq cursor_left_return
        lda spr0_hpos
        cmp #2
        bcc cursor_left_return
        // Action is OK
        lda #3                  // 3 - Left
        sta action
cursor_left_return:
        rts             
cursor_right:
        lda key_input
        cmp #$44                //d - Right
        bne select_from
        //Check position
        lda spr0_ind
        cmp #4
        beq cursor_right_return
        cmp #12
        beq cursor_right_return
        cmp #40
        beq cursor_right_return
        cmp #46
        beq cursor_right_return
        lda spr0_hpos
        cmp #7
        bcs cursor_right_return
        // Action is OK
        lda #4                  // 4 - Right
        sta action
cursor_right_return:
        rts
select_from:
        lda key_input
        cmp #$31        // 1 - Player 1 from
        beq select_from_pl1
        cmp #$32        // 2 - Player 2 from
        beq select_from_pl2
        jmp select_to
select_from_pl1:
        // Check state
        ldx spr0_ind
        lda state_mem,x
        cmp #1
        bne select_from_return
        // Action is OK
        lda #5          // 5 - Player 1 select from
        sta action
        rts
select_from_pl2:
        // Check state
        ldx spr0_ind
        lda state_mem,x
        cmp #1
        bne select_from_return
        // Action is OK
        lda #6          // 6 - Player 2 select from
        sta action
select_from_return:
        rts
select_to:
        lda key_input
        cmp #$54        // t - To
        bne select_move
        // Check state
        ldx spr0_ind
        lda state_mem,x
        cmp #0
        bne select_to_return
        // Action is OK
        lda #7          // 7 - To
        sta action
select_to_return:
        rts
select_move:
        // lda key_input
        // cmp #$4A        // j - Jump (Move)
        // bne select_move_return
        // // Action is OK
        // lda #8          // 8 - Move
        // sta action
select_move_return:
        rts
process:
spr0_incverpos:
        lda action
        cmp #1                  // Up
        bne spr0_decverpos
        //Move
        sec
        lda SPRITE_0_Y
        sbc #jump_length
        sta SPRITE_0_Y
        //Increase ver position
        clc
        lda spr0_vpos
        adc #1
        sta spr0_vpos
        lda spr0_pos
        adc #10
        sta spr0_pos
        lda spr0_ind
        adc #7
        sta spr0_ind
        rts
spr0_decverpos:
        lda action
        cmp #2                  // Down
        bne spr0_inchorpos
        //Move
        clc
        lda SPRITE_0_Y
        adc #jump_length
        sta SPRITE_0_Y
        //Decrease ver position
        sec
        lda spr0_vpos
        sbc #1
        sta spr0_vpos
        lda spr0_pos
        sbc #10
        sta spr0_pos
        lda spr0_ind
        sbc #7
        sta spr0_ind
        rts
spr0_inchorpos:
        lda action
        cmp #4          // Right
        bne spr0_dechorpos
        //Move
        clc
        lda SPRITE_0_X
        adc #jump_length
        sta SPRITE_0_X
        //Increase hor position
        lda spr0_hpos
        adc #1
        sta spr0_hpos
        lda spr0_pos
        adc #1
        sta spr0_pos
        lda spr0_ind
        adc #1
        sta spr0_ind
        rts
spr0_dechorpos:
        lda action
        cmp #3          // Left
        bne change_player
        //Move
        sec
        lda SPRITE_0_X
        sbc #jump_length
        sta SPRITE_0_X
        //Decrease hor position
        lda spr0_hpos
        sbc #1
        sta spr0_hpos
        lda spr0_pos
        sbc #1
        sta spr0_pos
        lda spr0_ind
        sbc #1
        sta spr0_ind
        rts
change_player:
        lda action
        cmp #5          // 5 - Player 1 select from
        beq set_player1
        cmp #6          // 6 - Player 2 select from
        beq set_player2
        jmp set_to
set_player1:
        lda #1
        sta player
        jmp set_from
set_player2:
        lda #2
        sta player
        jmp set_from
set_from:
        lda spr0_ind
        sta move_from
        lda SPRITE_0_X
        sta SPRITE_1_X
        lda SPRITE_0_Y
        sta SPRITE_1_Y
        rts
set_to:
        lda action
        cmp #7
        bne move
        lda spr0_ind
        sta move_to
        lda SPRITE_0_X
        sta SPRITE_2_X
        lda SPRITE_0_Y
        sta SPRITE_2_Y
        jsr move                // Include move in to
        rts
move:
        lda action
        cmp #7                  // Include move in to
        bne move_done
        lda move_from
        cmp move_to
        bcs move_calc1       // C=1, from >= to
// Move from < Move to
        sec
        lda move_to
        sbc move_from
        sta move_distance
        lda move_distance
        cmp #2
        beq move_cont
        cmp #12
        beq move_cont
        cmp #14
        beq move_cont
        cmp #16
        beq move_cont
        rts                     // No jump
move_cont:
// Formula: From+(Dist/2)
        lsr //acc=dist/2
        sta move_holder
        clc
        lda move_from
        adc move_holder
        sta move_in_between
        ldx move_in_between
        lda state_mem,x
        cmp #1
        bne move_done
        jsr change_board
        rts
move_calc1:
// Move from >= Move to
        sec
        lda move_from
        sbc move_to
        sta move_distance
        cmp #2
        beq move_calc1_cont
        cmp #12
        beq move_calc1_cont
        cmp #14
        beq move_calc1_cont
        cmp #16
        beq move_calc1_cont
        rts                     // No jump
move_calc1_cont:
//Formula: From-(Dist/2)
        lsr //acc=dist/2
        sta move_holder
        sec
        lda move_from
        sbc move_holder
        sta move_in_between
        ldx move_in_between
        lda state_mem,x
        cmp #1
        bne move_done
        jsr change_board
move_done:
        rts
change_board:
//Change the board
        ldx move_from
        lda #hole
        sta state_mem,x
        ldx move_to
        lda #peg
        sta state_mem,x
        ldy move_in_between
        lda #hole
        sta state_mem,y
        jsr score_pl1
        jsr print_status        //to output
        jsr print_board         //to output
        rts
score_pl1:
        lda player
        cmp #1        // 1
        bne score_pl2
        clc
        lda pl1_score
        adc #1
        sta pl1_score
        rts
score_pl2:
        clc
        lda pl2_score
        adc #1
        sta pl2_score
        rts
output:
        lda action
        cmp #5
        beq print_status
        cmp #6
        beq print_status
        cmp #8
        beq print_status_board
        rts
print_status_board:
        jsr print_status
        jsr print_board
        rts
print_status:
//Player:
        lda #$13        // HOME.
        jsr CHR_OUT     // Print.
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda player
        cmp #1
        beq print_pl1
        cmp #2
        beq print_pl2
print_pl1:
        lda #$3C
        jsr CHR_OUT     // Print
        lda #$3C
        jsr CHR_OUT     // Print
        jmp print_p1score
print_pl2:
        lda #$3E
        jsr CHR_OUT     // Print
        lda #$3E
        jsr CHR_OUT     // Print
print_p1score:
//P1-Score:
        lda #$13        // HOME.
        jsr CHR_OUT     // Print.
        lda #$11        // Cursor down
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        ldx pl1_score   // Load low byte to X.
        lda #$00        // Load high byte to Acc.
        jsr $BDCD       // LINPRT (48589). Output a number in ASCII decimal digits.
//P2-Score:
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        lda #$1D        // Cursor right
        jsr CHR_OUT     // Print
        ldx pl2_score   // Load low byte to X.
        lda #$00        // Load high byte to Acc.
        jsr $BDCD       // LINPRT (48589). Output a number in ASCII decimal digits.
        rts
print_board:
        lda action
        cmp #8
        ldx #$00
        ldy #$00
print_board_r1:
        lda state_mem,y
        sta board_screenstart,x
        inx
        inx
        inx
        iny
        cpy #$07
        bcc print_board_r1
        ldx #$00
        ldy #$00
print_board_r2:
        lda state_mem+7,y
        sta board_screenstart-120,x
        inx
        inx
        inx
        iny
        cpy #$07
        bcc print_board_r2
        ldx #$00
        ldy #$00
print_board_r3:
        lda state_mem+14,y
        sta board_screenstart-240,x
        inx
        inx
        inx
        iny
        cpy #$07
        bcc print_board_r3
        ldx #$00
        ldy #$00
print_board_r4:
        lda state_mem+21,y
        sta board_screenstart-360,x
        inx
        inx
        inx
        iny
        cpy #$07
        bcc print_board_r4
        ldx #$00
        ldy #$00
print_board_r5:
        lda state_mem+28,y
        sta board_screenstart-480,x
        inx
        inx
        inx
        iny
        cpy #$07
        bcc print_board_r5
        ldx #$00
        ldy #$00
print_board_r6:
        lda state_mem+35,y
        sta board_screenstart-600,x
        inx
        inx
        inx
        iny
        cpy #$07
        bcc print_board_r6
        ldx #$00
        ldy #$00
print_board_r7:
        lda state_mem+42,y
        sta board_screenstart-720,x
        inx
        inx
        inx
        iny
        cpy #$07
        bcc print_board_r7
print_done:
        rts
print_cords:
        lda #$31
        sta board_screenstart-3
        sta board_screenstart+120
        lda #$32
        sta board_screenstart-123
        sta board_screenstart+123
        lda #$33
        sta board_screenstart-243
        sta board_screenstart+126
        lda #$34
        sta board_screenstart-363
        sta board_screenstart+129
        lda #$35
        sta board_screenstart-483
        sta board_screenstart+132
        lda #$36
        sta board_screenstart-603
        sta board_screenstart+135
        lda #$37
        sta board_screenstart-723
        sta board_screenstart+138
        rts

// Custom Chars
*=$3000 //char 0 (A)
// 0: hole (circle)
.byte 60,66,129,129,129,129,66,60
// 1: peg (filled circle)
.byte 60,126,255,255,255,255,126,60
// 2: no hole (filled square)
.byte 0,0,0,0,0,0,0,0
//.byte 255,255,255,255,255,255,255,255
/*
0:
**********
*00111100* 60
*01000010* 66
*10000001* 129
*10000001* 129
*10000001* 129
*10000001* 129
*01000010* 66
*00111100* 60
**********
*/

/*
1:
**********
*00111100* 60
*01111110* 126
*11111111* 255
*11111111* 255
*11111111* 255
*11111111* 255
*01111110* 126
*00111100* 60
**********
*/

/*
2:
**********
*11111111* 255
*10000001* 129
*10000001* 129
*10000001* 129
*10000001* 129
*10000001* 129
*10000001* 129
*11111111* 255
**********
*/

*=13760
// Cursor
sprite_0:
.byte $3f,$81,$fc,$20,$00,$04,$20,$00
.byte $04,$20,$00,$04,$20,$00,$04,$20
.byte $00,$04,$20,$00,$04,$20,$00,$04
.byte $20,$00,$04,$20,$00,$04,$20,$00
.byte $04,$20,$00,$04,$20,$00,$04,$20
.byte $00,$04,$20,$00,$04,$20,$00,$04
.byte $20,$00,$04,$20,$00,$04,$20,$00
.byte $04,$3f,$81,$fc,$00,$00,$00,$05

// From
sprite_1:
.byte $00,$00,$00,$00,$08,$00,$00,$1c
.byte $00,$00,$2a,$00,$00,$08,$00,$00
.byte $08,$00,$00,$08,$00,$00,$08,$00
.byte $08,$00,$10,$10,$00,$08,$3f,$81
.byte $fc,$10,$00,$08,$08,$00,$10,$00
.byte $08,$00,$00,$08,$00,$00,$08,$00
.byte $00,$08,$00,$00,$2a,$00,$00,$1c
.byte $00,$00,$08,$00,$00,$00,$00,$05

// To
sprite_2:
.byte $00,$00,$00,$00,$08,$00,$00,$08
.byte $00,$00,$08,$00,$00,$08,$00,$00
.byte $2a,$00,$00,$1c,$00,$00,$08,$00
.byte $02,$00,$40,$01,$00,$80,$3f,$81
.byte $fc,$01,$00,$80,$02,$00,$40,$00
.byte $08,$00,$00,$1c,$00,$00,$2a,$00
.byte $00,$08,$00,$00,$08,$00,$00,$08
.byte $00,$00,$08,$00,$00,$00,$00,$05