: emu
  : query 11 io ;
  : title!         0 query ; # s --
  : show_cursor!   1 query ; # 0/1 --
  : poll_count!    2 query ; # n --
  : poll           3 query ; # --
  : timer_rate_hz  4 query ; # -- n
  : timer_rate_hz! 5 query ; # n --
  : timer_handler! 6 query ; # addr --
;