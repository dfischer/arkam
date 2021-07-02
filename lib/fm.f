require: lib/core.f

MODULE

  : query 4 io ;
  : param! 4 query ;  

  : p, ( n -- n+ ) dup , ? 10590 * 5320 + 10000 / ;
  here as: pitch_table
  110  p, p, p, p, p, p, p, p, p, p, p, p, drop cr
  220  p, p, p, p, p, p, p, p, p, p, p, p, drop cr
  440  p, p, p, p, p, p, p, p, p, p, p, p, drop cr
  880  p, p, p, p, p, p, p, p, p, p, p, p, drop cr
  1760 p, p, p, p, p, p, p, p, p, p, p, p, drop cr

---EXPOSE---

  : fm:voice!     0 query ; # i --
  : fm:operator!  1 query ; # i --
  : fm:play       2 query ; # freq --
  : fm:stop       3 query ;
  : fm:param!     param!  ; # v i --
  : fm:algo!      5 query ; # i --

  ( param )
  : fm:attack!    0 param! ; # v --
  : fm:decay!     1 param! ; # v --
  : fm:sustain!   2 param! ; # v --
  : fm:release!   3 param! ; # v --
  : fm:mod_ratio! 4 param! ; # v --
  : fm:fb_ratio!  5 param! ; # v --
  : fm:wave!      6 param! ; # v --
  : fm:ampfreq!   7 param! ; # v --
  : fm:fm_level!  8 param! ; # v --
  : fm:pan!       9 param! ; # v --

  : fm:deluxe_color ( -- c3 c2 c1 c0 )
    0xFAFAFA # 3 fg
    0xF80898 # 2 accent
    0x00C8C8 # 1 sub
    0x313131 # 0 bg
    ( 4 [ ppu:palette_color! ] for )
  ;

END
