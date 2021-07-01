require: lib/core.f
require: lib/sarkam.f
require: lib/basic_sprite.f
require: lib/entity.f



( ===== mouse ===== )

val: mouse:x
val: mouse:y
val: mouse:lx
val: mouse:ly
val: mouse:lp
val: mouse:rx
val: mouse:ry
val: mouse:rp

&mouse:x &mouse:y mouse:pos!
&mouse:lx &mouse:ly &mouse:lp mouse:left!
&mouse:rx &mouse:ry &mouse:rp mouse:right!

: mouse:listen emu:poll ;



( ===== put text/num ===== )

# basic_sprite.f should load character sprite
# at same ascii code

MODULE

  val: x   val: y
  val: ox  val: s

  7 as: w
  9 as: h

  : right x w + x! ;

  : next s 1 + s! ;

  : newline ox x!  y h + y! ;

  : draw ( spr -- ) sprite:i! x y sprite:plot ;

  : loop
    [ s b@
      0  [ STOP            ] ;CASE
      10 [ newline next GO ] ;CASE
      32 [ right   next GO ] ;CASE
      draw right next GO
    ] while
  ;

---EXPOSE---

  w as: put_text:w

  : put_text ( x y s ) s! y! dup x! ox! loop ;

END


MODULE

  11 as: max ( i32: max "-2147483648" )
  max 1 + allot as: buf
  val: n  val: p  val: nega  val: q  val: r  val: x  val: y  val: base

  : init buf max + p! ;
  : check buf p > IF "too big num" panic THEN ;
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
    n 0 = IF x y "0" put_text rdrop RET THEN
    n dup neg != IF RET THEN ( 0x80000000 * -1 = 0x80000000 )
    10 base = IF x y "-2147483648" put_text rdrop RET THEN
    16 base = IF x y "-80000000"   put_text rdrop RET THEN
    "?: invalid base" panic
  ;
  : run ( n x y -- ) y! x! n!
    check_min
    check_sign
    init
    read
    put_sign
    x y p put_text
  ;
  
---EXPOSE---

  : put_dec ( n x y -- ) 10 base! run ;
  : put_hex ( n x y -- ) 16 base! run ;

END


MODULE

  16 as: base
  3 allot as: buf
  val: x  val: y

---EXPOSE---

  : put_ff ( n x y -- )
    y! x!
    0xFF and base /mod ( q r )
    >hex buf 1 + b!
    >hex buf     b!
    x y buf put_text
  ;

END



( ===== button ===== )

MODULE

  128 as: max
  
  max ENTITY btn
    COMPONENT show
    COMPONENT callback
    COMPONENT param
    COMPONENT pressed
    COMPONENT x
    COMPONENT y
    COMPONENT width
    COMPONENT height
    ( draw )
    COMPONENT dparam
    COMPONENT dcallback
  END
  
  ( current button ) val: id
  ( draw origin ) val: dx  val: dy
  ( mouse ) val: mx  val: my  val: mp
  
  : hover? mx my id x id y id width id height hover_rect? ;
  
  : clicked? mp IF no ELSE id pressed THEN ;
  
  : click
    no id >pressed
    id param id callback >r
  ;
  
  : handle_click
    hover? not IF no id >pressed RET THEN
    clicked? IF click THEN
    mp IF
      yes id >pressed
      dy 1 + dy!
    ELSE
      dy 1 - dy!
    THEN
  ;
  
  : draw ( id -- )
    id! ( draw-callback can use id )
    id x dx! id y dy!
    handle_click
    id dcallback >r
  ;

  : new ( -- id ) btn entity:new [ "Too many buttons" panic ] unless ;

  : create ( param x y dparam callback width height dcallback -- id )
    # q: ( param -- )
    new id!
    id >dcallback
    id >height
    id >width
    id >callback
    id >dparam
    id >y
    id >x
    id >param
    yes id >show
    no  id >pressed
    id
  ;

---EXPOSE---

  : btn:delete ( id -- ) btn entity:kill ;

  : btn:draw_all ( -- )
    mouse:x  mx!
    mouse:y  my!
    mouse:lp mp!
    btn [
      dup show IF draw ELSE drop THEN
    ] entity:each
  ;

  ( ----- sprite button ----- )
  8 as: sprbtn:width
  8 as: sprbtn:height

  : sprbtn:create ( param x y spr q -- id )
    # dparam: sprite id
    sprbtn:width sprbtn:height
    [ id dparam sprite:i! dx dy sprite:plot ] create
  ;

  ( ----- text button ----- )
  9 as: txtbtn:height

  : txtbtn:create ( param x y str q -- id )
    # dparam: text
    over s:len put_text:w * 1 - ( width )
    txtbtn:height
    [ dx dy id dparam put_text
      3 ppu:color!
      dx  dy 9 +  dx id width + 1 -  dy 9 + line
    ] create
  ;

END



: mgui:update
  mouse:listen
  btn:draw_all
;
