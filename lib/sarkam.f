require: lib/core.f
require: lib/ppu.f
require: lib/mouse.f
require: lib/emu.f
require: lib/app.f


: plot ( x y -- )
  # ignore outer position
  over 0          <  IF 2drop RET THEN
  over ppu:width  >= IF 2drop RET THEN
  dup  0          <  IF 2drop RET THEN
  dup  ppu:height >= IF 2drop RET THEN
  ppu:plot
;



MODULE

  # bresenham's algorithm
  
  val: x0  val: y0
  val: x1  val: y1
  val: dx  val: dy
  val: sx  val: sy
  val: e1  val: e2
  
  : CHECK
    x0 x1 != IF RET THEN
    y0 y1 != IF RET THEN
    rdrop ( exit loop )
  ;
  
  : loop
    x0 y0 plot
    CHECK
    e1 2 * e2!
    e2 dy neg > IF
      e1 dy - e1!
      x0 sx + x0!
    THEN
    e2 dx < IF
      e1 dx + e1!
      y0 sy + y0!
    THEN
    AGAIN
  ;
  
---EXPOSE---

  : line ( x0 y0 x1 y1 -- )
    y1! x1! y0! x0!
    x1 x0 - abs dx!
    y1 y0 - abs dy!
    x1 x0 > IF 1 ELSE -1 THEN sx!
    y1 y0 > IF 1 ELSE -1 THEN sy!
    dx dy - e1!
    loop
  ;
  
END



( ===== draw loop ===== )

MODULE
  # ----- Usage -----
  # draw_loop only:
  #   30 [ foo:update foo:draw ] draw_loop:register!
  # with other update routine:
  #   30 [ foo:update foo:draw ] draw_loop:init
  #   [ other_loop draw_loop:update HALT ] emu:timer_handler!

  val: fps
  val: frames
  val: callback
  val: i
  
  : init ( fps callback -- )
    callback! fps!
    emu:timer_rate_hz fps / dup frames! i!
  ;

  : draw
    ppu:0clear
    callback call
    ppu:switch!
  ;

---EXPOSE---

  : draw_loop:update
    i 1 + dup frames >= IF drop draw 0 THEN i!
  ;

  : draw_loop:update_halt draw_loop:update HALT ;

  : draw_loop:register! ( fps callback -- )
    init &draw_loop:update_halt emu:timer_handler!
  ;

END
