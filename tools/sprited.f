require: lib/core.f
require: lib/mgui.f



( ===== global ===== )

8 as: padding

val: selected  0 selected!



( ===== showcase ===== )

MODULE

  256 as: max
  8 as: w  8 as: h
  8 as: spr/line
  8 as: lines
  max lines / as: max_lines
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

  val: row  val: col
  val: x  val: y

  val: basespr  ( start sprite on showcase )
  val: rowspr   ( start sprite on row )
  val: spr

  : basealign ( i -- i ) spr/line / spr/line * ;
  : basespr! ( i -- ) ? max + max mod basealign ? cr basespr! ;

  : row! ( row -- )
    dup row!
    dup spr/line * basespr + max mod rowspr!
    h * top + y!
  ;

  : col! ( col -- )
    dup col!
    dup rowspr + spr!
    w * left + x!
  ;

  ( buttons )

  bl bw + padding + as: btn_left
  padding           as: btn_top

  0 btn_left btn_top      64 [ drop basespr spr/line - basespr! ] sprbtn:create drop
  0 btn_left btn_top 16 + 64 [ drop basespr spr/line + basespr! ] sprbtn:create drop


  ( draw )

  : draw_selected
    3 ppu:color!
    x border - y border - 
    w border + h border +
    rect
  ;

  : draw_showcase
    8 [ row!
      8 [ col!
        spr sprite:i!
        x y sprite:plot
        spr selected = IF draw_selected THEN
      ] for
    ] for
  ;

  : draw_border 1 ppu:color! bl bt bw bh rect ;

  : draw_id selected idx idy put_ff ;

---EXPOSE---

  : showcase:draw ( -- )
    draw_border
    draw_showcase
    draw_id
  ;

END



30 [
  mgui:update
  showcase:draw
]  draw_loop:register!

[ ( wait ) GO ] while
