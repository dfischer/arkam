require: lib/core.f
require: lib/sarkam.f
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
