require: lib/sarkam.f
require: lib/basic_sprite.f
require: lib/entity.f



( ===== button ===== )

PRIVATE

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
  
  ( current button ) var: id
  ( draw origin ) var: dx  var: dy
  ( mouse ) var: mx  var: my  var: mp
  
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

PUBLIC

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



( ===== slider ===== )

PRIVATE

  128 as: max_sliders

  3 as: border_color
  1 as: bar_color

  max_sliders ENTITY slider
    COMPONENT vmax
    COMPONENT vmin
    COMPONENT vrange
    COMPONENT pressed
    COMPONENT width
    COMPONENT height
    COMPONENT x
    COMPONENT y
    COMPONENT right
    COMPONENT v
    COMPONENT callback ( v param -- )
    COMPONENT param
    COMPONENT barpos ( x )
  END

  var: id  ( current )

  : v>barpos id vmin - id width * id vrange / id width dec min ; # pre:id

  : >x ( x id -- ) 2dup >x tuck width + swap >right ;

  : update! ( v id -- )
    dup id! [ vmin ] [ vmax ] biq clamp
    dup id >v
    v>barpos id >barpos
  ;

  : v! ( v id -- )
    dup >r update! r> id!
    id callback ?dup IF id v swap id param swap call THEN
  ;

  : draw_border
    border_color ppu:color!
    id x id y id width id height rect
  ;

  : draw_bar
    bar_color ppu:color!
    id barpos id x + id y dec  id barpos id x +  id height dec id y inc + line
  ;

  : press
    mouse:x id right > IF id vmax dec id v! RET THEN
    mouse:x id x <= IF id vmin id v! RET THEN
    mouse:x id x - ( width-ranged )
    id vrange * id width / ( value-ranged ) id vmin +
    id v!
  ;

  : hover? mouse:x mouse:y id x id y id width id height hover_rect? ;

  : handle_mouse
    mouse:lp not IF no id >pressed RET THEN
    hover? IF yes id >pressed press RET THEN
    id pressed IF press RET THEN
    ( noop )
  ;

  : draw ( id -- ) id!
    handle_mouse
    draw_border
    draw_bar
  ;

PUBLIC

  # range: 0 <= v <= max
  #
  # example:
  #  var: freq
  #  slider:new
  #    [ drop freq! ] slider:callback!
  #    200 8   slider:size!
  #    10  10  slider:pos!
  #    400 880 slider:range!
  #    0       slider:param!
  #    slider:validate!
  #    as: freq_slider

  : slider:new ( -- id )
    slider entity:new [ "Too many sliders" panic ] unless ;

  : slider:size! ( id width height -- id )
    >r over r> over >height >width
  ;

  : slider:pos! ( id x y -- id )
    >r >r
    dup width not IF "set size first" panic THEN
    dup r> swap >x dup r> swap >y
  ;

  : slider:range! ( id min max -- id )
    pullup id!
    2dup swap - id >vrange
    inc id >vmax id >vmin
    id vmin id v!
    id
  ;

  : slider:callback! ( id q -- id ) over >callback ;

  : slider:param! ( id p -- id ) over >param ;

  : slider:v ( id -- v ) v ;
  : slider:v! ( v id -- ) v! ;
  : slider:update! ( v id -- ) update! ;

  : slider:validate ( id -- err ng | id ok ) id!
    id v id vmin <  [ "Out of range" ng ] ;IF
    id v id vmax >= [ "Out of range" ng ] ;IF
    id width  0 <=  [ "No width"     ng ] ;IF
    id height 0 <=  [ "No height"    ng ] ;IF
    id ok
  ;

  : slider:validate! ( id -- id )
    slider:validate [ panic ] unless ;

  : ?slider ( id -- id )
    "v " epr dup v .
    "x " epr dup x ..
    "y " epr dup y .
    "w " epr dup width ..
    "h " epr dup height .
    "vmax " epr dup vmax ..
    "vmin " epr dup vmin .
  ;

  : slider:draw_all
    slider ' draw entity:each
  ;

END



: mgui:update
  btn:draw_all
  slider:draw_all
;
