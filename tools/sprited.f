require: lib/core.f
require: lib/mgui.f


256           as: spr_max
8             as: spr_w
8             as: spr_h
spr_w spr_h * as: spr_size

8 as: spr/line
8 as: lines
spr/line lines * as: spr/screen



( ===== buf and file ===== )

spr_max spr_size * as: spr_bytes

MODULE

  256     as: len
  len dec as: max
  val: id

---EXPOSE---

  app:argc 2 != [ "filename required" panic ] unless

  len allot as: fname
  fname 2 max app:get_arg [ "Too long filename" panic ] unless

  fname loadfile
    dup filesize spr_bytes != [ "Invalid sprite file" panic ] when
    filedata as: spr_buf
  
  spr_bytes allot as: spr_back
  spr_buf spr_back spr_bytes memcopy

  : reset_all ( -- ) spr_back spr_buf spr_bytes memcopy ;

  : save
    fname "wb" file:open! id!
    spr_buf spr_bytes id file:write!
    id file:close!
  ;

  : fname:draw 8 8 fname put_text ;

END



( view area )
spr_max dec spr/screen - as: spr_start

: load_area ( base -- )
  spr/screen [ ( base i -- base )
    dup spr_start + sprite:i!
    over + spr_max mod spr_size * spr_buf + sprite:load
  ] for drop
;


( base )
val: spr_base  ( start sprite on showcase )
: basealign ( i -- i ) spr/line / spr/line * ;
: spr_base! ( i -- ) spr_max + spr_max mod basealign dup spr_base! load_area ;
0 spr_base!


( select )
spr_start dec as: spr_target
val: selected
val: spr_adr ( target )

: selected!
  dup selected!
  spr_size * spr_buf +
  dup spr_adr!
  spr_target sprite:i! sprite:load
;

: reset ( -- )
  selected spr_size * ( offset )
  [ spr_back + ] [ spr_buf + ] biq spr_size memcopy
;

0 selected!


( view )

8 as: padding

padding 3 * as: gui_top


( ===== showcase ===== )

MODULE

  spr_max lines / as: max_lines
  1 as: border

  spr_w spr/line * as: width
  spr_h lines *    as: height

  padding border + as: left
  left width +     as: right
  gui_top border + as: top
  top height +     as: bottom

  left   border -     as: bl
  top    border -     as: bt
  width  border 2 * + as: bw
  height border 2 * + as: bh

  bl                as: idx
  bt bh + padding + as: idy

  val: row  val: col
  val: x  val: y

  val: spr
  val: rowspr
  val: actual

  : basespr+! ( n -- ) spr_base swap + spr_base! ;
  : basespr-! ( n -- ) spr_base swap - spr_base! ;

  : row! ( row -- )
    dup row!
    dup spr/line * rowspr!
    spr_h * top + y!
  ;

  : col! ( col -- )
    dup col!
    dup rowspr + spr_start + spr!
    dup rowspr + spr_base + spr_max mod actual!
    spr_w * left + x!
  ;

  ( scroll buttons )

  bl bw + 4 +  as: btn_left
  top          as: btn_top
  btn_top bh + as: btn_bottom

  : scrollbtn ( y spr q -- )
    >r >r >r 0 btn_left r> r> r> sprbtn:create drop
  ;

  : current! selected spr/line 3 * - spr_base! ;

  btn_top         0x8A [ drop spr/screen basespr-! ] scrollbtn
  btn_top    9  + 0x8E [ drop spr/line   basespr-! ] scrollbtn
  btn_top    25 + 0x90 [ drop current!             ] scrollbtn
  btn_bottom 17 - 0x8F [ drop spr/line   basespr+! ] scrollbtn
  btn_bottom 8  - 0x8B [ drop spr/screen basespr+! ] scrollbtn

  ( draw )

  : draw_cursor
    3 ppu:color!
    x border - y border - 
    spr_w border + spr_h border +
    rect
  ;

  : draw_showcase
    8 [ row!
      8 [ col!
        spr sprite:i!
        x y sprite:plot
        actual selected = IF draw_cursor THEN
      ] for
    ] for
  ;

  : draw_border 1 ppu:color! bl bt bw bh rect ;

  : draw_id selected idx idy put_ff ;

  ( select )

  : handle_select
    mouse:lp not IF RET THEN
    mouse:x mouse:y left top width height hover_rect? not IF RET THEN
    mouse:x left - spr_w /   mouse:y top - spr_h /   ( col row )
    spr/line * + spr_base + spr_max mod selected!
  ;

---EXPOSE---

  : showcase:draw ( -- )
    handle_select
    draw_border
    draw_showcase
    draw_id
  ;

  btn_left spr_w + as: showcase:right

END



( ===== editor ===== )

MODULE

  spr_w dup * as: width
  spr_h dup * as: height
  
  1 as: border
  
  padding 3 * as: leftpad
  
  gui_top                  border + as: top
  showcase:right leftpad + border + as: left
  left width +                      as: right
  top height +                      as: bottom

  val: x  val: y
  val: col val: row
  val: adr
  : dot  adr b@ ;
  : dot! adr b! ;
  
  : row!  dup row!  spr_h * top + y!  ;
  : col!
    dup col!
    dup spr_w * left + x!
    row spr_w * + spr_adr + adr!
  ;

  top  border - as: bt
  left border - as: bl
  width  border 2 * + as: bw
  height border 2 * + as: bh
  
  : draw_border
    1 ppu:color!
    bl bt bw bh rect
  ;
  
  : draw_canvas
    1 ppu:color!
    spr_h [ row!
      spr_w [ col!
        dot sprite:i!
        x y ppu:plot
        x y sprite:plot
      ] for
    ] for
  ;
  
  bl as: prv_x
  bt bh + 4 + as: prv_y
  
  : draw_preview
    spr_target sprite:i!
    prv_x prv_y sprite:plot
  ;

  ( ----- handle mouse ----- )

  val: pressed
  val: color  ( 0-3 ) 3 color!
  val: curcol ( current color )

  : hover? mouse:x mouse:y left top width height hover_rect? ;

  : where
    mouse:y top  - spr_h / row!
    mouse:x left - spr_w / col!
  ;

  : press
    pressed IF RET THEN yes pressed!
    dot IF 0 ELSE color THEN curcol!
  ;

  : paint curcol dot! ;

  : handle_mouse
    mouse:lp not IF no pressed! RET THEN
    hover? not IF RET THEN
    where press paint
  ;

  ( ----- color selector ----- )

  bottom 4 + as: sel_y

  : selector ( color x -- ) over sel_y swap [ color! ] sprbtn:create drop ;
  : sel_x ( color -- x ) 9 * 1 - right swap - ;

  3 dup sel_x selector
  2 dup sel_x selector
  1 dup sel_x selector

  sel_y 9 + as: under_y

  : draw_selcolor # underline
    3 ppu:color!
    color sel_x dup 7 + under_y swap over line
  ;

  ( ----- tools ----- )
  right padding + as: tool_x
  top as: tool_y
  0 tool_x tool_y "reset" [ drop reset ] txtbtn:create drop

---EXPOSE---

  : editor:draw
    handle_mouse
    draw_border
    draw_canvas
    draw_preview
    draw_selcolor
  ;
  
END



( ===== Toolbar ===== )

MODULE

  padding as: left
  ppu:height padding - as: bottom
  bottom 8 - as: top

---EXPOSE---

  0 left top "save" [ drop save ] txtbtn:create drop
  0 left 36 + top "reset all" [ drop reset_all ] txtbtn:create drop

END



30 [
  mgui:update
  showcase:draw
  editor:draw
  fname:draw
]  draw_loop:register!

[ ( wait ) GO ] while
