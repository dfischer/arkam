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



( ===== sprbtn : sprite button ===== )

MODULE

  128 as: max
  8 as: width ( sprite width )
  
  max ENTITY btn
    COMPONENT show
    COMPONENT sprite
    COMPONENT callback
    COMPONENT param
    COMPONENT pressed
    COMPONENT x
    COMPONENT y
  END
  
  ( current button ) val: id
  ( draw origin ) val: dx  val: dy
  ( mouse ) val: mx  val: my  val: mp
  
  : hover? mx my id x id y width width hover_rect? ;
  
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
  
  : draw ( id -- ) id!
    id x dx! id y dy!
    handle_click
    id sprite sprite:i!
    dx dy sprite:plot
  ;

---EXPOSE---

  : sprbtn:create ( param x y spr q -- )
    # q: ( param -- )
    btn entity:new! id!
    id >callback
    id >sprite
    id >y
    id >x
    id >param
    yes id >show
    no  id >pressed
  ;
  
  : sprbtn:delete ( id -- ) btn entity:kill ;
  
  : sprbtn:draw ( -- )
    mouse:x  mx!
    mouse:y  my!
    mouse:lp mp!
    btn [
      dup show IF draw ELSE drop THEN
    ] entity:each
  ;
  
END



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
