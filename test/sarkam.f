require: lib/sarkam.f
require: lib/basic_sprite.f

basic.spr:load

val: x
val: y

: move
  x 1 + ppu:width mod y!
  y 2 + ppu:height mod x!
;

30 [
  move
  64 sprite:i!
  x y sprite:plot
] draw_loop:register!

[ ( wait ) GO ] while
