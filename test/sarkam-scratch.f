require: lib/sarkam.f
  
: main
  init:run
  [ 10 10 " hello" put_text ] draw_loop:register
  draw_loop
;

' main turnkey: out/sarkam-scratch.ark
