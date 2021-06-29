require: lib/sarkam.f
require: lib/basic_sprite.f

basic.spr:load

val: x
val: y

: move
  x 2 + ppu:width mod y!
  y 3 + ppu:height mod x!
;

30 [
  move
  64 sprite:i!
  x y sprite:plot
] draw_loop:register!

[ ( wait ) GO ] while
