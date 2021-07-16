require: lib/sarkam.f
require: lib/basic_sprite.f
require: lib/entity.f
require: lib/mgui.f
require: lib/fm.f

fm:deluxe_color 4 [ ppu:palette_color! ] for

0 fm:voice!
0 fm:operator!


PRIVATE

  16 as: steps
  steps allot as: seq
  steps allot as: lifes
  var: idx ( current playing )
  var: playing
  var: dur ( frames per step )
  10 dur!
  var: swing ( frames to delay )
  1 swing!
  var: freq 440 freq!

  : at  ( i -- v ) seq + b@ ;
  : at! ( v i -- ) seq + b! ;
  : idx+! ( n -- ) idx + steps mod idx! ;
  : next ( -- ) 1 idx+! ;

  : life  ( -- v ) lifes idx + b@ ;
  : life! ( v -- ) lifes idx + b! ;

  ( ----- sequencer ----- )

  var: elapsed

  : swinged idx 2 mod IF 0 ELSE swing THEN dur + ;

  : trigger
    idx at ?dup 0 = IF RET THEN
    life!
    freq fm:play
  ;

  : detrigger
    life dec dup life!
    1 < IF fm:stop THEN
  ;

  : update
    playing not IF RET THEN
    elapsed dup inc elapsed! not [ trigger ] ;when
    detrigger
    elapsed swinged >= IF 0 elapsed! next THEN
  ;

  : clear 0 idx! 0 elapsed! ;

  : play_all clear yes playing! ;

  : stop_all clear fm:stop no playing! ;

  ( ----- draw ----- )

  var: ox  var: oy
  4 as: rows  4 as: cols  4 as: pad
  8 as: w  8 as: h
  var: dx  var: dy  var: row  var: col
  var: cur ( current drawing idx )

  var: pressed  var: mval  var: mx  var: my  var: mi
  : width  w cols * pad cols * + ;
  : height h rows * pad rows * + ;
  : hover? mouse:x mouse:y ox oy width height hover_rect? ;
  : where
    mouse:x ox - w pad + / mx!
    mouse:y oy - h pad + / my!
    my rows * mx + mi!
  ;
  : place mval mi at! ;
  : paint hover? not IF RET THEN where place ;
  : press
    yes pressed!
    where mi at IF 0 ELSE dur 2 - THEN mval!
    place
  ;
  : handle_mouse
    mouse:lp not IF no pressed! RET THEN
    pressed IF paint RET THEN
    hover? not IF RET THEN
    press
  ;

  : row_y! h pad + * oy + dy! ;
  : col_x! w pad + * ox + dx! ;
  : col! row cols * + cur! ;

  : draw_cursor
    playing not IF RET THEN
    cur idx != IF RET THEN
    2 sprite:i!
    dx dy inc sprite:plot
  ;

  : draw_all
    handle_mouse
    rows [ dup row! row_y!
      cols [ dup col! col_x!
        draw_cursor
        cur at IF 1 ELSE 3 THEN sprite:i!
        dx dy sprite:plot
      ] for
    ] for
  ;

  ( init )
  MARKER: <init>
    rand:init
    steps [ 2 rand IF 0 ELSE dur 2 - THEN swap at! ] for
  <init>

PUBLIC

  : seq:pos! ( x y -- ) oy! ox! ;

  : seq:update ( -- ) update ;
  : seq:draw ( -- ) draw_all ;

  : seq:play play_all ;
  : seq:stop stop_all ;

  : seq:freq! freq! ;

END



( ===== params ===== )

PRIVATE
  32 as: max

  max ENTITY sliders
    COMPONENT callback
    COMPONENT val
    COMPONENT vx
    COMPONENT vy
    COMPONENT label
    COMPONENT lx
    COMPONENT ly
    COMPONENT op
  END

  var: id
  
  40 as: swidth
  8  as: sheight
  4  as: pad
  var: ox var: oy
  7 3 * as: lwidth

  : run ( v id -- ) 2dup >val dup callback >r ;

  : val_pos!   ( ox oy ) id >vy lwidth + swidth + pad + pad + id >vx ;
  : label_pos! ( ox oy ) id >ly id >lx ;
  : slider_pos ( ox oy -- sx sy ) [ lwidth + pad + ] dip ;

  : new_slider ( x y min max label callback -- id )
    sliders entity:new [ " Too many params" panic ] unless id!
    id >callback
    id >label

    slider:new
      id   slider:param!
      ' run slider:callback!
      swidth sheight slider:size!
      pushdown slider:range!
      ( ox oy sid )
      >r
        2dup val_pos!
        2dup label_pos!
        slider_pos
      r> pushdown ( sid sx sy )
      slider:pos!
      slider:validate!
    ( -- sid )
  ;

  : draw_label id lx id ly id label put_text ;

  : draw_num id val id vx id vy put_dec ;

  : draw_all
    sliders [ id! draw_label draw_num ] entity:each
  ;

  10  10 440 880 " FRQ" [ drop seq:freq! ] new_slider drop
  110 10 0   7   " ALG" [ drop fm:algo!  ] new_slider drop

  var: p
  : op! op fm:operator! ;
  : --- ( x y -- x y+ x y ) dup 12 + swap >r over r> ;
  : oparams ( x y op -- ) p!
    --- 0   3   " WAV" [ op! fm:wave!      ] new_slider p swap >op
    --- 0   255 " ATK" [ op! fm:attack!    ] new_slider p swap >op
    --- 0   255 " DCY" [ op! fm:decay!     ] new_slider p swap >op
    --- 0   255 " SUS" [ op! fm:sustain!   ] new_slider p swap >op
    --- 0   255 " REL" [ op! fm:release!   ] new_slider p swap >op
    --- 0   17  " MOD" [ op! fm:mod_ratio! ] new_slider p swap >op
    --- 0   255 "  FB" [ op! fm:fb_ratio!  ] new_slider p swap >op
    --- 0   255 " AFQ" [ op! fm:amp_freq!  ] new_slider p swap >op
    --- 0   255 "  FM" [ op! fm:fm_level!  ] new_slider p swap >op
    2drop
  ;

  10  26 0 oparams
  110 26 1 oparams

PUBLIC

  : params:draw draw_all ;

END


  10 140 seq:pos!
0 60 140 " play" [ seq:play ] txtbtn:create drop
0 60 150 " stop" [ seq:stop ] txtbtn:create drop


[
  seq:update
  mgui:update
  params:draw
  seq:draw
] draw_loop:register

draw_loop
