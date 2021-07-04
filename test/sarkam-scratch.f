require: lib/sarkam.f
require: lib/basic_sprite.f
require: lib/entity.f
require: lib/mgui.f
require: lib/fm.f

fm:deluxe_color 4 [ ppu:palette_color! ] for

0 fm:voice!
0 fm:operator!


( ===== slider ===== )

MODULE

  128 as: max_sliders

  3 as: border_color
  1 as: bar_color

  max_sliders ENTITY slider
    COMPONENT vmax
    COMPONENT vmin
    COMPONENT vrange
    COMPONENT pressed
    COMPONENT width
    COMPONENT height
    COMPONENT x
    COMPONENT y
    COMPONENT right
    COMPONENT v
    COMPONENT callback ( v param -- )
    COMPONENT param
    COMPONENT barpos ( x )
  END

  val: id  ( current )

  : v>barpos id vmin - id width * id vrange / id width dec min ; # pre:id

  : >x ( x id -- ) 2dup >x tuck width + swap >right ;

  : update! ( v id -- )
    dup id! [ vmin ] [ vmax ] biq clamp
    dup id >v
    v>barpos id >barpos
  ;

  : v! ( v id -- )
    dup >r update! r> id!
    id callback ?dup IF id v swap id param swap call THEN
  ;

  : draw_border
    border_color ppu:color!
    id x id y id width id height rect
  ;

  : draw_bar
    bar_color ppu:color!
    id barpos id x + id y dec  id barpos id x +  id height dec id y inc + line
  ;

  : press
    mouse:x id right > IF id vmax dec id v! RET THEN
    mouse:x id x <= IF id vmin id v! RET THEN
    mouse:x id x - ( width-ranged )
    id vrange * id width / ( value-ranged ) id vmin +
    id v!
  ;

  : hover? mouse:x mouse:y id x id y id width id height hover_rect? ;

  : handle_mouse
    mouse:lp not IF no id >pressed RET THEN
    hover? IF yes id >pressed press RET THEN
    id pressed IF press RET THEN
    ( noop )
  ;

  : draw ( id -- ) id!
    handle_mouse
    draw_border
    draw_bar
  ;

---EXPOSE---

  # range: 0 <= v <= max
  #
  # example:
  #  val: freq
  #  slider:new
  #    [ drop freq! ] slider:callback!
  #    200 8   slider:size!
  #    10  10  slider:pos!
  #    400 880 slider:range!
  #    0       slider:param!
  #    slider:validate!
  #    as: freq_slider

  : slider:new ( -- id )
    slider entity:new [ "Too many sliders" panic ] unless ;

  : slider:size! ( id width height -- id )
    >r over r> over >height >width
  ;

  : slider:pos! ( id x y -- id )
    >r >r
    dup width not IF "set size first" panic THEN
    dup r> swap >x dup r> swap >y
  ;

  : slider:range! ( id min max -- id )
    pullup id!
    2dup swap - id >vrange
    inc id >vmax id >vmin
    id vmin id v!
    id
  ;

  : slider:callback! ( id q -- id ) over >callback ;

  : slider:param! ( id p -- id ) over >param ;

  : slider:v ( id -- v ) v ;
  : slider:v! ( v id -- ) v! ;
  : slider:update! ( v id -- ) update! ;

  : slider:validate ( id -- err ng | id ok ) id!
    id v id vmin <  [ "Out of range" ng ] ;IF
    id v id vmax >= [ "Out of range" ng ] ;IF
    id width  0 <=  [ "No width"     ng ] ;IF
    id height 0 <=  [ "No height"    ng ] ;IF
    id ok
  ;

  : slider:validate! ( id -- id )
    slider:validate [ panic ] unless ;

  : ?slider ( id -- id )
    "v " epr dup v .
    "x " epr dup x ..
    "y " epr dup y .
    "w " epr dup width ..
    "h " epr dup height .
    "vmax " epr dup vmax ..
    "vmin " epr dup vmin .
  ;

  : slider:draw
    slider &draw entity:each
  ;

END



MODULE

  16 as: steps
  steps allot as: seq
  steps allot as: lifes
  val: idx ( current playing )
  val: playing
  val: dur ( frames per step )
  20 dur!
  val: freq 440 freq!

  : at  ( i -- v ) seq + b@ ;
  : at! ( v i -- ) seq + b! ;
  : idx+! ( n -- ) idx + steps mod idx! ;
  : next ( -- ) 1 idx+! ;

  : life  ( -- v ) lifes idx + b@ ;
  : life! ( v -- ) lifes idx + b! ;

  ( ----- sequencer ----- )

  val: elapsed

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
    elapsed dup inc elapsed! not [ trigger ] ;IF
    detrigger
    elapsed dur >= IF 0 elapsed! next THEN
  ;

  : clear 0 idx! 0 elapsed! ;

  : play_all clear yes playing! ;

  : stop_all clear fm:stop no playing! ;

  ( ----- draw ----- )

  val: ox  val: oy
  4 as: rows  4 as: cols  4 as: pad
  8 as: w  8 as: h
  val: dx  val: dy  val: row  val: col
  val: cur ( current drawing idx )

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
    rows [ dup row! row_y!
      cols [ dup col! col_x!
        draw_cursor
        cur at IF 1 ELSE 3 THEN sprite:i!
        dx dy sprite:plot
      ] for
    ] for
  ;

  ( init )
  MARKER <init>
    rand:init
    steps [ 2 rand IF 0 ELSE 5 THEN swap at! ] for
  <init>

---EXPOSE---

  200 ox! 10 oy!

  : seq:pos! ( x y -- ) oy! ox! ;
  : seq:draw ( -- ) update draw_all ;

  : seq:play play_all ;
  : seq:stop stop_all ;

  : seq:freq! freq! ;

END



( ===== params ===== )

MODULE
  16 as: max

  max ENTITY sliders
    COMPONENT callback
    COMPONENT val
    COMPONENT vx
    COMPONENT vy
    COMPONENT label
    COMPONENT lx
    COMPONENT ly
  END

  val: id
  
  40 as: swidth
  8  as: sheight
  4  as: pad
  val: ox val: oy
  7 4 * as: lwidth

  : run ( v id -- ) 2dup >val callback >r ;

  : val_pos!   ( ox oy ) id >vy lwidth + swidth + pad + pad + id >vx ;
  : label_pos! ( ox oy ) id >ly id >lx ;
  : slider_pos ( ox oy -- sx sy ) [ lwidth + pad + ] dip ;

  : new_slider ( x y min max label callback -- )
    sliders entity:new [ "Too many sliders" panic ] unless id!
    id >callback
    id >label

    slider:new
      id   slider:param!
      &run slider:callback!
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
    drop
  ;

  : draw_label id lx id ly id label put_text ;

  : draw_num id val id vx id vy put_dec ;

  : draw_all
    sliders [ id! draw_label draw_num ] entity:each
  ;

  : all_op ( v q -- ) 4 [ fm:operator! 2dup call ] for 2drop ;

  val: freq
  10 10 440 880 "freq" [ dup freq! seq:freq! ] new_slider
  10 20 0   7   "algo" [ fm:algo! ] new_slider
  10 30 0   255 " atk" [ [ fm:attack!  ] all_op ] new_slider
  10 40 0   255 " dcy" [ [ fm:decay!   ] all_op ] new_slider
  10 50 0   255 " sus" [ [ fm:sustain! ] all_op ] new_slider
  10 60 0   255 " rel" [ [ fm:release! ] all_op ] new_slider
  10 70 0   3   "wave" [ [ fm:wave!    ] all_op ] new_slider

---EXPOSE---

  : params:draw draw_all ;

END


0 10 100 "play" [ seq:play ] txtbtn:create drop
0 10 110 "stop" [ seq:stop ] txtbtn:create drop

[
  mgui:update
  slider:draw
  params:draw
  seq:draw
] draw_loop:register

draw_loop
