include: "sarkam.sol"
include: "entity.sol"
include: "basic_sprite.sol"
include: "mgui.sol"


: main_loop
  mgui:update
;


: wait_loop AGAIN ;

: main
  "scratch" emu:title!
  yes emu:show_cursor!
  rand:init
  mgui:init
  basic_sprite:load

  30 &main_loop draw_loop:register!

  wait_loop
;