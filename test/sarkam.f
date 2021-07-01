require: lib/sarkam.f
require: lib/basic_sprite.f
require: lib/entity.f
require: lib/mgui.f

basic.spr:load


val: sprbtnid
"pressed" 10 10 64 [ pr sprbtnid btn:delete ] sprbtn:create sprbtnid!

val: txtbtnid
"txt" 120 10 "foo" [ pr txtbtnid btn:delete ] txtbtn:create txtbtnid!

val: n 2147483600 n!

30 [
  mgui:update
  20 20 "hello" put_text
  n 1 + dup n!
  dup 20 30 put_dec
      20 40 put_hex
  0xFF 20 50 put_ff
] draw_loop:register!

[ ( wait ) GO ] while
