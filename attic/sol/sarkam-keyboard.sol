include: "sarkam.sol"
include: "entity.sol"
include: "basic_sprite.sol"
include: "mgui.sol"


: keytable
  val: buf  const: len 10
  val: i
  val: latest
  const: a 97
  const: z 122
  : key! buf + b! ;
  : key  buf + b@ ;
  : next_i i 1 + len mod i! ;
  : >buf ( c -- ) buf i + b! next_i ;
  : char? ( c -- ? ) dup 32 < IF no RET END 126 < ;
  : update_latest ( k s -- ) IF latest! END ;
  : put_char ( k s -- )
    not IF drop RET END
    dup char? not IF drop 63 END >buf ;
  : update [ ( k s -- )
      &update_latest &put_char bibi
    ] keyboard:queue:pop_each
  ;
  : draw
    val: x  val: y  val: row  val: i
    latest IF latest 8 8 put_num END
    8 20 buf put_text
  ;
  : init len 1 + ( null ) allot buf! ;
;



: main_loop
  mgui:update
  keytable:update
  keytable:draw
;


: wait_loop AGAIN ;


: main
  "keyboard test" emu:title!
  yes emu:show_cursor!
  rand:init
  mgui:init
  basic_sprite:load

  30 &main_loop draw_loop:register!

  keyboard:queue:listen!
  keytable:init

  wait_loop
;