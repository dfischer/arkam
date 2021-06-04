include: "ppu.sol"
include: "mouse.sol"
include: "emu.sol"
include: "app.sol"


: plot ( x y -- )
  # ignore outer position
  over 0          <  IF 2drop RET END
  over ppu:width  >= IF 2drop RET END
  dup  0          <  IF 2drop RET END
  dup  ppu:height >= IF 2drop RET END
  ppu:plot ;



: line ( x0 y0 x1 y1 -- )
  # bresenham's algorithm
  val: x0  val: y0
  val: x1  val: y1
  val: dx  val: dy
  val: sx  val: sy
  val: e1  val: e2
  : CHECK
    x0 x1 != IF RET END
    y0 y1 != IF RET END
    rdrop ( exit loop ) ;
  : loop
    x0 y0 plot
    CHECK
    e1 2 * e2!
    e2 dy neg > IF
      e1 dy - e1!
      x0 sx + x0!
    END
    e2 dx < IF
      e1 dx + e1!
      y0 sy + y0!
    END
    AGAIN ;
  y1! x1! y0! x0!
  x1 x0 - abs dx!
  y1 y0 - abs dy!
  x1 x0 > IF 1 ELSE -1 END sx!
  y1 y0 > IF 1 ELSE -1 END sy!
  dx dy - e1!
  loop
;



: rect ( x y w h )
  val: x  val: y  val: w  val: h
  1 - h! 1 - w! y! x!
  ( top    )  x     y      x w +  y     line
  ( bottom )  x     y h +  x w +  y h + line
  ( left   )  x     y      x      y h + line
  ( right  )  x w + y      x w +  y h + line
;


: fill_rect ( x y w h )
  val: x  val: y  val: w  val: h
  h! w! y! x!
  h [ y +
    w [ ( y dx -- y )
      x + over plot
    ] for drop
  ] for
;


: circle ( r x y -- )
  # bresenham's algorithm
  val: x   val: y   val: r
  val: cx  val: cy  val: d  val: dh  val: dd
  : loop
    cx cy > IF RET END
    d 0 < IF
      d dh + d!
      dh 2 + dh!
      dd 2 + dd!
    ELSE
      d dd + d!
      dh 2 + dh!
      dd 4 + dd!
      cy 1 - cy!
    END
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
  y! x! r!
  1 r - d!
  3 dh!
  5 2 r * - dd!
  r cy!
  0 cx!
  loop
;


: hover_rect? ( x1 y1 x0 y0 w h -- yes | no )
  # dx = x1 - x0
  # dy = y1 - y0
  # x1 < x0         => dx < 0
  # x1 > x0 + w - 1 => w - dx < 1
  # y1 < y0 + h     => dy - h < 0
  val: dx  val: dy  val: w  val: h
  h! w! >r swap r> - dy! - dx!
  dx     0 < IF no RET END
  dy     0 < IF no RET END
  w dx - 1 < IF no RET END
  dy h - 0 <
;



: draw_loop
  # ===== Usage =====
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
  : update i 1 + dup frames >= IF drop draw 0 END i! ;
  : update_halt update HALT ;
  : register! ( fps callback -- )
    init &update_halt emu:timer_handler! ;
;



( ===== Key Queue ===== )

: kq
  # 0 len
  # 1 buffer
  # 2 state_len
  # 3 state
  # 4 idx (current)
  # 5 head
  const: size 7
  val: q ( temporary, do not use in recursion )
  : c@ cells q + @ ;
  : c! cells q + ! ;
  : len     0 c@ ; # -- n
  : len!    0 c! ; # n --
  : buf     1 c@ ; # -- a
  : buf!    1 c! ; # a --
  : slen    2 c@ ; # -- n
  : slen!   2 c! ; # n --
  : status  3 c@ ; # -- a
  : status! 3 c! ; # a --
  : idx     4 c@ ; # -- n
  : idx!    4 c! ; # n --
  : head    5 c@ ; # -- n
  : head!   5 c! ; # n --
  : name    6 c@ ; # -- s
  : name!   6 c! ; # s --
  : create ( name len state_len -- addr )
    val: l  val: sl  val: nm
    sl! l! nm!
    size cells allot q!
    l        len!
    l allot  buf!
    sl       slen!
    sl allot status!
    0        idx!
    0        head!
    nm       name!
    q
  ;
  : invalid ( c -- ) ? "invalid code for " epr name panic ;
  : check   ( c -- c )
    dup 0    <  IF invalid END
    dup slen >= IF invalid END
  ;
  : state  ( c -- s ) check status + b@ ;
  : state! ( s c -- ) check status + b! ;
  : next_i!    idx  1 + len mod idx!  ;
  : next_head! head 1 + len mod head! ;
  : empty? idx head = ;
  : >buf ( c -- ) buf head + b! next_head! ;
  : buf> ( -- c no | yes )
    empty? IF yes RET END
    buf idx + b@ no next_i!
  ;
  : push ( up/down code queue -- )
    val: c  val: s
    q!
    check c! s!
    s IF ( down )
      c state IF
        RET ( repeat )
      ELSE
        1
      END
    ELSE ( up )
      0
    END
    c state!
    c >buf
  ;
  : pop ( queue -- code state no | yes )
    q! buf> IF yes RET END dup state no
  ;
  : pop_each ( q queue -- ) # q: code state --
    val: cb
    : loop q pop IF RET END cb call AGAIN ;
    q! cb! loop
  ;
;



( ===== keyboard ===== )

: keyboard
  : query 5 io ;
  : handler! 0 query ; # q --

  ( ----- queue by ring buffer ----- )
  : queue
    const: len  32
    const: slen 256
    val: q
    : name "keyboard_queue" ;
    : init name len slen kq:create q! ;
    : listen!
      q not IF init END
      [ q kq:push HALT ] handler!
    ;
    : pop ( -- keycode state ) q kq:pop ;
    : pop_each ( q[ keycode state -- ] -- ) q kq:pop_each ;
  ;
;



( ===== Gamepad ===== )

: gamepad
  : query 7 io ;
  : available 0 query ; # -- n
  : handler!  1 query ; # q -- (q: state button pad )

  ( ----- queue by ring buffer ----- )
  # only for one controller
  : queue
    const: len  32
    const: slen 64
    val: q
    : name "gamepad_queue" ;
    : init name len slen kq:create q! ;
    : listen!
      q not IF init END
      [ drop ( ignore pad number )
        q kq:push HALT
      ] handler!
    ;
    : pop ( -- button state ) q kq:pop ;
    : pop_each ( q[ button state -- ] -- ) q kq:pop_each ;
  ;
;