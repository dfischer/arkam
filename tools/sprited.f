require: lib/core.f
require: lib/mgui.f



( ===== global ===== )

8 as: padding

val: selected  0 selected!



( ===== showcase ===== )

MODULE

  8 as: w  8 as: h
  8 as: spr/line
  8 as: lines
  1 as: border

  w spr/line * as: width
  h lines *    as: height

  padding border + as: left
  left width +     as: right
  padding border + as: top
  top height +     as: bottom

  left   border -     as: bl
  top    border -     as: bt
  width  border 2 * + as: bw
  height border 2 * + as: bh

  bl                as: idx
  bt bh + padding + as: idy

  val: x  val: y
  val: baseline

  ( draw )

  : draw_showcase
    8 [ ( y -- ) dup h * top + y!
      8 [ ( y x -- )
        dup w * left + x!
        over spr/line * + sprite:i!
        x y sprite:plot
      ] for drop
    ] for
  ;

  : draw_border 1 ppu:color! bl bt bw bh rect ;

  : draw_selected
    3 ppu:color!
    selected spr/line mod w * left + border - ( x )
    selected spr/line /   h * top  + border - ( x y )
    w border + h border + rect
  ;

  : draw_id selected idx idy put_ff ;

---EXPOSE---

  : showcase:draw ( -- )
    draw_showcase
    draw_border
    draw_selected
    draw_id
  ;

END



30 [
  mgui:update
  showcase:draw
]  draw_loop:register!

[ ( wait ) GO ] while
