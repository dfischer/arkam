include: "sarkam.sol"
include: "entity.sol"
include: "basic_sprite.sol"
include: "mgui.sol"


: gamepad
  : query 7 io ;
  : available 0 query ;
  : handler!  1 query ;
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

  [ ? drop ? drop ? drop cr HALT ] gamepad:handler!

  wait_loop
;
