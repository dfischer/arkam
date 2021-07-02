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



MODULE

  val: x  val: y  val: w  val: h

---EXPOSE---

  : rect ( x y w h )
    1 - h! 1 - w! y! x!
    ( top    )  x     y      x w +  y     line
    ( bottom )  x     y h +  x w +  y h + line
    ( left   )  x     y      x      y h + line
    ( right  )  x w + y      x w +  y h + line
  ;

END



MODULE

  val: x  val: y  val: w  val: h

---EXPOSE---

  : fill_rect ( x y w h )
    h! w! y! x!
    h [ y +
      w [ ( y dx -- y )
        x + over plot
      ] for drop
    ] for
  ;

END



MODULE

  # bresenham's algorithm
  val: x   val: y   val: r
  val: cx  val: cy  val: d  val: dh  val: dd

  : loop
    cx cy > IF RET THEN
    d 0 < IF
      d dh + d!
      dh 2 + dh!
      dd 2 + dd!
    ELSE
      d dd + d!
      dh 2 + dh!
      dd 4 + dd!
      cy 1 - cy!
    THEN
    cy x +  cx y +  plot
    cx x +  cy y +  plot
    cx neg x +  cy y +  plot
    cy neg x +  cx y +  plot
    cy neg x +  cx neg y +  plot
    cx neg x +  cy neg y +  plot
    cx x +  cy neg y +  plot
    cy x +  cx neg y +  plot
    cx 1 + cx!
    AGAIN ;

---EXPOSE---

  : circle ( r x y -- )
    y! x! r!
    1 r - d!
    3 dh!
    5 2 r * - dd!
    r cy!
    0 cx!
    loop
  ;

END



MODULE

  val: dx  val: dy  val: w  val: h

---EXPOSE---

  : hover_rect? ( x1 y1 x0 y0 w h -- yes | no )
    # point(x1 y1) on rect(x0 y0 w h) ?
    # dx = x1 - x0
    # dy = y1 - y0
    # x1 < x0         => dx < 0
    # x1 > x0 + w - 1 => w - dx < 1
    # y1 < y0 + h     => dy - h < 0
  
    h! w! >r swap r> - dy! - dx!
    dx     0 < IF no RET THEN
    dy     0 < IF no RET THEN
    w dx - 1 < IF no RET THEN
    dy h - 0 <
  ;

END



( ===== draw loop ===== )

MODULE
  # usage:
  #   [ some_draw ] draw_loop:register!
  #   draw_loop

  val: callback

  : draw
    ppu:0clear
    callback call
    ppu:switch!
  ;

---EXPOSE---

  : draw_loop:register ( q -- ) callback! ;

  : draw_loop draw AGAIN ;

END

