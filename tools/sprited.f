require: lib/mgui.f

lexicon: [sprited]
[sprited] EDIT
LEXI [sprited] [file] REFER

init:run


256           as: spr-max
8             as: spr-w
8             as: spr-h
spr-w spr-h * as: spr-size

8 as: spr/line
8 as: lines
spr/line lines * as: spr/screen



( ===== buf and file ===== )

spr-max spr-size * as: spr-bytes

COVER

  256     as: len
  len dec as: max
  var: id

SHOW

  len allot as: fname
  opt:read! [ "filename required" panic ] unless
  max s:check [ "Too long file name" panic ] unless
  fname s:copy
  fname loadfile
    dup filesize spr-bytes != [ "Invalid sprite file" panic ] when
    filedata as: spr-buf

  spr-bytes allot as: spr-back
  spr-buf spr-back spr-bytes memcopy

  : reset-all ( -- ) spr-back spr-buf spr-bytes memcopy ;

  : save
    fname "wb" file:open! id!
    spr-buf spr-bytes id file:write!
    id file:close!
  ;

  : fname:draw 8 8 fname put-text ;

END



( view area )
spr-max dec spr/screen - as: spr-start

: load-area ( base -- )
  spr/screen [ ( base i -- base )
    dup spr-start + sprite:i!
    over + spr-max mod spr-size * spr-buf + sprite:load
  ] for drop
;


( base )
var: spr-base  ( start sprite on showcase )
: basealign ( i -- i ) spr/line / spr/line * ;
: spr-base! ( i -- ) spr-max + spr-max mod basealign dup spr-base! load-area ;
0 spr-base!


( select )
spr-start dec as: spr-target
var: selected
var: spr-adr ( target )

: selected!
  dup selected!
  spr-size * spr-buf +
  dup spr-adr!
  spr-target sprite:i! sprite:load
;

: reset ( -- )
  selected spr-size * ( offset )
  [ spr-back + ] [ spr-buf + ] biq spr-size memcopy
;

0 selected!


( view )

8 as: padding

padding 3 * as: gui-top


( ===== showcase ===== )

COVER

  spr-max lines / as: max-lines
  1 as: border

  spr-w spr/line * as: width
  spr-h lines *    as: height

  padding border + as: left
  left width +     as: right
  gui-top border + as: top
  top height +     as: bottom

  left   border -     as: bl
  top    border -     as: bt
  width  border 2 * + as: bw
  height border 2 * + as: bh

  bl          as: idx
  bt bh + 4 + as: idy

  var: row  var: col
  var: x  var: y

  var: spr
  var: rowspr
  var: actual

  : basespr+! ( n -- ) spr-base swap + spr-base! ;
  : basespr-! ( n -- ) spr-base swap - spr-base! ;

  : row! ( row -- )
    dup row!
    dup spr/line * rowspr!
    spr-h * top + y!
  ;

  : col! ( col -- )
    dup col!
    dup rowspr + spr-start + spr!
    dup rowspr + spr-base + spr-max mod actual!
    spr-w * left + x!
  ;

  ( scroll buttons )

  bl bw + 4 +  as: btn-left
  top          as: btn-top
  btn-top bh + as: btn-bottom

  : scrollbtn ( y spr q -- )
    >r >r >r 0 btn-left r> r> r> sprbtn:create drop
  ;

  : current! selected spr/line 3 * - spr-base! ;

  btn-top         0x8A [ drop spr/screen basespr-! ] scrollbtn
  btn-top    9  + 0x8E [ drop spr/line   basespr-! ] scrollbtn
  btn-top    25 + 0x90 [ drop current!             ] scrollbtn
  btn-bottom 17 - 0x8F [ drop spr/line   basespr+! ] scrollbtn
  btn-bottom 8  - 0x8B [ drop spr/screen basespr+! ] scrollbtn

  ( draw )

  : draw-cursor
    3 ppu:color!
    x border - y border -
    spr-w border + spr-h border +
    rect
  ;

  : draw-showcase
    8 [ row!
      8 [ col!
        spr sprite:i!
        x y sprite:plot
        actual selected = IF draw-cursor THEN
      ] for
    ] for
  ;

  : draw-border 1 ppu:color! bl bt bw bh rect ;

  : draw-id selected idx idy put-ff ;

  ( select )

  : handle-select
    mouse:lp not IF RET THEN
    mouse:x mouse:y left top width height hover-rect? not IF RET THEN
    mouse:x left - spr-w /   mouse:y top - spr-h /   ( col row )
    spr/line * + spr-base + spr-max mod selected!
  ;

SHOW

  : showcase:draw ( -- )
    handle-select
    draw-border
    draw-showcase
    draw-id
  ;

  btn-left spr-w + as: showcase:right

END



( ===== editor ===== )

COVER

  spr-w dup * as: width
  spr-h dup * as: height

  1 as: border

  padding 3 * as: leftpad

  gui-top                  border + as: top
  showcase:right leftpad + border + as: left
  left width +                      as: right
  top height +                      as: bottom

  var: x  var: y
  var: col var: row
  var: adr
  : dot  adr b@ ;
  : dot! adr b! ;

  : row!  dup row!  spr-h * top + y!  ;
  : col!
    dup col!
    dup spr-w * left + x!
    row spr-w * + spr-adr + adr!
  ;

  top  border - as: bt
  left border - as: bl
  width  border 2 * + as: bw
  height border 2 * + as: bh

  : draw-border
    1 ppu:color!
    bl bt bw bh rect
  ;

  : draw-canvas
    1 ppu:color!
    spr-h [ row!
      spr-w [ col!
        dot sprite:i!
        x y ppu:plot
        x y sprite:plot
      ] for
    ] for
  ;

  bl as: prv-x
  bt bh + 4 + as: prv-y

  : draw-preview
    spr-target sprite:i!
    prv-x prv-y sprite:plot
  ;

  ( ----- handle mouse ----- )

  var: pressed
  var: color  ( 0-3 ) 3 color!
  var: curcol ( current color )

  : hover? mouse:x mouse:y left top width height hover-rect? ;

  : where
    mouse:y top  - spr-h / row!
    mouse:x left - spr-w / col!
  ;

  : press
    pressed IF RET THEN yes pressed!
    dot
    0     [ color curcol! ] ;case
    color [ 0     curcol! ] ;case
    drop color curcol!
  ;

  : paint curcol dot! ;

  : handle-mouse
    mouse:lp not IF no pressed! RET THEN
    hover? not IF RET THEN
    where press paint
  ;

  ( ----- color selector ----- )

  bottom 4 + as: sel-y

  : selector ( color x -- ) over sel-y swap [ color! ] sprbtn:create drop ;
  : sel-x ( color -- x ) 9 * 1 - right swap - ;

  3 dup sel-x selector
  2 dup sel-x selector
  1 dup sel-x selector

  sel-y 9 + as: under-y

  : draw-selcolor # underline
    3 ppu:color!
    color sel-x dup 7 + under-y swap over line
  ;

  ( ----- tools ----- )
  right padding + as: tool-x
  top as: tool-y
  0 tool-x tool-y "reset" [ drop reset ] txtbtn:create drop

SHOW

  : editor:draw
    handle-mouse
    draw-border
    draw-canvas
    draw-preview
    draw-selcolor
  ;

END



( ===== Toolbar ===== )

COVER

  padding as: left
  ppu:height padding - as: bottom
  bottom 8 - as: top

SHOW

  0 left top "save" [ drop save ] txtbtn:create drop
  0 left 36 + top "reset all" [ drop reset-all ] txtbtn:create drop

END



[
  mgui:update
  showcase:draw
  editor:draw
  fname:draw
]  draw-loop:register

draw-loop
