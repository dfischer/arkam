require: lib/sarkam.f
require: lib/basic_sprite.f
require: lib/entity.f
require: lib/mgui.f

basic.spr:load


"pressed" 10 10 64 [ pr ?stack ] sprbtn:create


30 [
  sprbtn:draw
  20 20 "hello" put_text
] draw_loop:register!


[ ( wait ) GO ] while
