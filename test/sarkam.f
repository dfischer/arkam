require: lib/sarkam.f
require: lib/basic_sprite.f
require: lib/entity.f
require: lib/mgui.f

basic.spr:load


val: x 10 x!
val: y 10 y!
val: w 20 w!
val: h 20 h!

: drawrect
  mouse:x mouse:y x y w h hover_rect?
  [ x y w h fill_rect ] [ x y w h rect ] if
;

30 [
  64 sprite:i!
  3 ppu:color!
  drawrect
] draw_loop:register!

[ ( wait ) GO ] while
