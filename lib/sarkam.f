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
  
  0 val: x0  0 val: y0
  0 val: x1  0 val: y1
  0 val: dx  0 val: dy
  0 val: sx  0 val: sy
  0 val: e1  0 val: e2
  
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
