require: lib/sarkam.f
require: lib/basic_sprite.f
require: lib/entity.f
require: lib/mgui.f

basic.spr:load


"pressed" 10 10 64 [ pr ?stack ] sprbtn:create

val: n 2147483600 n!

30 [
  sprbtn:draw
  20 20 "hello" put_text
  n 1 + dup n!
  dup 20 30 put_dec
      20 40 put_hex
  255 20 50 put_ff
] draw_loop:register!


[ ( wait ) GO ] while
