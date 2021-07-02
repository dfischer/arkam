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
    COMPONENT max
    COMPONENT min
    COMPONENT vrange
    COMPONENT pressed
    COMPONENT width
    COMPONENT height
    COMPONENT x
    COMPONENT y
    COMPONENT v
    COMPONENT callback
    COMPONENT barpos ( x )
  END

  val: id  ( current )

  : v>barpos id width * id vrange / ; # pre:id

  : v! ( v id -- )
    dup id! [ min ] [ max ] biq clamp
    dup id >v
    v>barpos id >barpos
  ;

  : draw_border
    border_color ppu:color!
    id x id y id width id height rect
  ;

  : draw_bar
    bar_color ppu:color!
    id barpos id x + id y   id barpos id x +  id height dec id y + line
  ;

  : draw ( id -- ) id! draw_border draw_bar ;

---EXPOSE---

  # range: min <= value < max

  : slider:new ( -- id )
    slider entity:new [ "Too many sliders" panic ] unless ;

  : slider:pos! ( id x y -- id )
    >r over r> over >y >x ;

  : slider:size! ( id width height -- id )
    >r over r> over >height >width ;

  : slider:range! ( id min max -- id )
    pullup id!
    2dup swap - dec id >vrange
    id >max id >min ;

  : slider:callback! ( id q -- id ) over >callback ;

  : slider:v! ( v id -- ) v! ;

  : ?slider ( id -- id )
    "v " epr dup v .
    "x " epr dup x ..
    "y " epr dup y .
    "w " epr dup width ..
    "h " epr dup height .
    "min " epr dup min ..
    "max " epr dup max .
  ;

  : slider:draw
    slider &draw entity:each
  ;

END


val: sld
slider:new
  10 10 slider:pos!
  40 8  slider:size!
  0  256 slider:range!
  [ sld ? "v " epr . ] slider:callback!
  dup 200 swap slider:v!
drop


val: n 2147483600 n!

[
  mgui:update
  slider:draw
] draw_loop:register

draw_loop

