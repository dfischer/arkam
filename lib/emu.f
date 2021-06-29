: emu:query 11 io ;
: emu:title!         0 emu:query ; # s --
: emu:show_cursor!   1 emu:query ; # 0/1 --
: emu:poll_count!    2 emu:query ; # n --
: emu:poll           3 emu:query ; # --
: emu:timer_rate_hz  4 emu:query ; # -- n
: emu:timer_rate_hz! 5 emu:query ; # n --
: emu:timer_handler! 6 emu:query ; # addr --
