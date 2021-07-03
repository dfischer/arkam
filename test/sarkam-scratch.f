require: lib/sarkam.f
require: lib/basic_sprite.f
require: lib/entity.f
require: lib/mgui.f
require: lib/fm.f

fm:deluxe_color 4 [ ppu:palette_color! ] for


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
    COMPONENT callback
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
    id callback ?dup IF id v swap call THEN
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
    id
  ;

  : slider:callback! ( id q -- id ) over >callback ;

  : slider:v ( id -- v ) v ;
  : slider:v! ( v id -- ) v! ;
  : slider:update! ( v id -- ) update! ;

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



0 fm:voice!

val: freq
slider:new
  40 8   slider:size!
  10 10  slider:pos!
  440 880 slider:range!
  [ freq! ] slider:callback!
  440 swap slider:v!

: label-freq freq 52 10 put_dec ;


val: op
slider:new
  40 8  slider:size!
  10 20 slider:pos!
  0  3  slider:range!
  [ op! ] slider:callback!
  0 swap slider:v!

: label-op op 52 20 put_dec ;


0 10 100 "play" [ freq fm:play ] txtbtn:create drop

[
  mgui:update
  slider:draw
  label-freq
  label-op
] draw_loop:register

draw_loop
