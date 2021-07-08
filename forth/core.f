# ===== Core Library =====


( ===== Boolean ===== )

-1 as: ok
 0 as: ng

ok as: yes
ng as: no

ok as: true
ng as: false

ok as: GO
ng as: STOP


: not 0 != ;


: putc 0 1 io ;
: foo 64 putc 10 putc ;
: bye 0 HALT ;
: main foo bye ;
