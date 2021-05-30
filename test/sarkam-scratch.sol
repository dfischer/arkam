include: "sarkam.sol"
include: "entity.sol"
include: "basic_sprite.sol"
include: "mgui.sol"


: keyboard
  : query 5 io ;
  : handler! 0 query ; # q --

  ( ----- queue by ring buffer ----- )
  : queue
    val: buf    const: len 32        ( keycode ring buffer )
    val: state  const: state_len 256 ( indexed by keycode. 0:up 1:down )
    val: i  val: head
    : invalid ( k -- ) ? "invalid keycode" panic ;
    : check ( keycode -- keycode )
      dup 0 <          IF invalid END
      dup state_len >= IF invalid END
    ;
    : key  ( k -- s ) check state + b@ ;
    : key! ( s k -- ) check state + b! ;
    : init
      0 i!
      0 head!
      len allot buf!
      state_len allot state!
    ;
    : next_i!    i    1 + len mod i! ;
    : next_head! head 1 + len mod head! ;
    : empty? i head = ;
    : >buf ( k -- ) buf head + b! next_head! ;
    : buf> ( -- k no | yes )
      empty? IF yes RET END
      buf i + b@ no next_i!
    ;
    : push ( up/down keycode -- )
      val: k  val: s
      check k! s!
      s IF ( down )
        k key IF
          RET ( repeat )
        ELSE
          1
        END
      ELSE ( up )
        0
      END
      k key!
      k >buf
    ;
    : listen!
      buf not IF init END
      [ push HALT ] handler!
    ;
    : pop ( -- keycode state no | yes )
      buf> IF yes RET END dup key no
    ;
  ;
;



: pop_keys
  : loop
    keyboard:queue:pop IF RET END
    ? drop ? drop cr AGAIN
  ;
  loop
;



: main_loop
  mgui:update
  pop_keys
;


: wait_loop AGAIN ;


: main
  "scratch" emu:title!
  yes emu:show_cursor!
  rand:init
  mgui:init
  basic_sprite:load

  30 &main_loop draw_loop:register!

  keyboard:queue:listen!

  wait_loop
;