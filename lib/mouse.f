: mouse:query 6 io ;

: mouse:pos!   0 mouse:query ; # &x &y --
: mouse:left!  1 mouse:query ; # &x &y &press --
: mouse:right! 2 mouse:query ; # &x &y &press --
