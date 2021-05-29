include: "sarkam.sol"
include: "entity.sol"
include: "basic_sprite.sol"
include: "mgui.sol"


: keyboard
  : query 5 io ;
  : handler! 0 query ; # q --
;


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

  [ ?hex drop ?hex drop HALT ] keyboard:handler!

  wait_loop
;