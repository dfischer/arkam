require: lib/ppu.f
require: lib/mouse.f
require: lib/emu.f
require: lib/basic_sprite.f

[ basic.spr:load ] >init



: plot ( x y -- )
  # ignore outer position
  over 0          <  IF 2drop RET THEN
  over ppu:width  >= IF 2drop RET THEN
  dup  0          <  IF 2drop RET THEN
  dup  ppu:height >= IF 2drop RET THEN
  ppu:plot
;



PRIVATE

  # bresenham's algorithm
  
  var: x0  var: y0
  var: x1  var: y1
  var: dx  var: dy
  var: sx  var: sy
  var: e1  var: e2
  
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
  
PUBLIC

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



PRIVATE

  var: x  var: y  var: w  var: h

PUBLIC

  : rect ( x y w h )
    1 - h! 1 - w! y! x!
    ( top    )  x     y      x w +  y     line
    ( bottom )  x     y h +  x w +  y h + line
    ( left   )  x     y      x      y h + line
    ( right  )  x w + y      x w +  y h + line
  ;

END



PRIVATE

  var: x  var: y  var: w  var: h

PUBLIC

  : fill_rect ( x y w h )
    h! w! y! x!
    h [ y +
      w [ ( y dx -- y )
        x + over plot
      ] for drop
    ] for
  ;

END



PRIVATE

  # bresenham's algorithm
  var: x   var: y   var: r
  var: cx  var: cy  var: d  var: dh  var: dd

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

PUBLIC

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



PRIVATE

  var: dx  var: dy  var: w  var: h

PUBLIC

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

PRIVATE
  # usage:
  #   [ some_draw ] draw_loop:register!
  #   draw_loop

  var: callback

  : draw
    ppu:0clear
    callback call
    ppu:switch!
  ;

PUBLIC

  : draw_loop:register ( q -- ) callback! ;

  : draw_loop draw AGAIN ;

END



( ===== mouse ===== )

var: mouse:x
var: mouse:y
var: mouse:lx
var: mouse:ly
var: mouse:lp
var: mouse:rx
var: mouse:ry
var: mouse:rp

[
  var' mouse:x var' mouse:y mouse:pos!
  var' mouse:lx var' mouse:ly var' mouse:lp mouse:left!
  var' mouse:rx var' mouse:ry var' mouse:rp mouse:right!
] >init



( ===== put text/num ===== )

# basic_sprite.f should load character sprite
# at same ascii code

PRIVATE

  var: x   var: y
  var: ox  var: s

  7 as: w
  9 as: h

  : right x w + x! ;

  : next s 1 + s! ;

  : newline ox x!  y h + y! ;

  : draw ( spr -- ) sprite:i! x y sprite:plot ;

  : loop
    [ s b@
      0  [ STOP            ] ;case
      10 [ newline next GO ] ;case
      32 [ right   next GO ] ;case
      draw right next GO
    ] while
  ;

PUBLIC

  w as: put_text:w

  : put_text ( x y s ) s! y! dup x! ox! loop ;

END



PRIVATE

  11 as: max ( i32: max " -2147483648" )
  max 1 + allot as: buf
  var: n  var: p  var: nega  var: q  var: r  var: x  var: y  var: base

  : init buf max + p! ;
  : check buf p > IF " too big num" panic THEN ;
  : put ( n -- ) p 1 - p! p b! ;
  : put_sign nega IF 45 put THEN ;
  : read ( -- )
    check
    n base /mod r! q!
    r >hex put
    q 0 = IF RET THEN q n! AGAIN
  ;
  : check_sign n 0 < IF n neg n! yes ELSE no THEN nega! ;
  : check_min ( n -- )
    # minimum number
    n 0 = IF x y " 0" put_text rdrop RET THEN
    n dup neg != IF RET THEN ( 0x80000000 * -1 = 0x80000000 )
    10 base = IF x y " -2147483648" put_text rdrop RET THEN
    16 base = IF x y " -80000000"   put_text rdrop RET THEN
    " ?: invalid base" panic
  ;
  : run ( n x y -- ) y! x! n!
    check_min
    check_sign
    init
    read
    put_sign
    x y p put_text
  ;
  
PUBLIC

  : put_dec ( n x y -- ) 10 base! run ;
  : put_hex ( n x y -- ) 16 base! run ;

END



PRIVATE

  16 as: base
  3 allot as: buf
  var: x  var: y

PUBLIC

  : put_ff ( n x y -- )
    y! x!
    0xFF and base /mod ( q r )
    >hex buf 1 + b!
    >hex buf     b!
    x y buf put_text
  ;

END

