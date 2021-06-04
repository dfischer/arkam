include: "sarkam.sol"
include: "entity.sol"
include: "basic_sprite.sol"
include: "mgui.sol"



: arrows
  val: up
  val: down
  val: left
  val: right
  const: ls 0x1C  const: lx 8   const: ly 18
  const: us 0x1E  const: ux 18  const: uy 8
  const: ds 0x1F  const: rx 28  const: ry 18
  const: rs 0x1D  const: dx 18  const: dy 28
  val: cx  val: cy
  const: cs 0x92
  : cx+ cx + ppu:width  mod cx! ;
  : cy+ cy + ppu:height mod cy! ;
  : update_keys ( k s -- )
    swap
    11 [ up!    ] ;CASE
    12 [ down!  ] ;CASE
    13 [ left!  ] ;CASE
    14 [ right! ] ;CASE
    drop
  ;
  : update ( k s -- )
    up    IF -1 cy+ END
    down  IF  1 cy+ END
    left  IF -1 cx+ END
    right IF  1 cx+ END
  ;
  : draw_btn ( x y flag n ) ppu:sprite:i! + ppu:sprite:plot ;
  : draw
    cs ppu:sprite:i! cx cy ppu:sprite:plot
    lx ly left  ls draw_btn
    ux uy up    us draw_btn
    dx dy down  ds draw_btn
    rx ry right rs draw_btn
  ;
;


: main_loop
  mgui:update
  [ arrows:update_keys ] gamepad:queue:pop_each
  arrows:update
  arrows:draw
;


: wait_loop AGAIN ;

: main
  "gamepad test" emu:title!
  yes emu:show_cursor!
  rand:init
  mgui:init
  basic_sprite:load

  30 &main_loop draw_loop:register!

  gamepad:queue:listen!

  wait_loop
;
