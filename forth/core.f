# ===== Forth Core =====



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



( ===== Stack ===== )

: nip   swap drop ; # a b -- b
: 2dup  over over ; # a b -- a b a b
: 2drop drop drop ; # x x --
: 3drop drop drop drop ; # x x x --



( ===== Compare ===== )

: <=  > inv ; # a b -- ?
: >=  < inv ; # a b -- ?


: max  over over < IF swap THEN drop ; # a b -- a|b
: min  over over > IF swap THEN drop ; # a b -- a|b



( ===== Arithmetics ===== )

: /   ( a b -- a/b ) /mod drop ;
: mod ( a b -- a%b ) /mod swap drop ;

: neg ( n -- n ) -1 * ;

: abs dup 0 < IF neg THEN ;

: inc 1 + ;
: dec 1 - ;



( ===== bit ===== )

: <<  ( n -- n )     lsft ;
: >>  ( n -- n ) neg lsft ;
: >>> ( n -- n ) neg asft ;



( ===== Memory ===== )

4 as: cell
: cells ( n -- n ) cell * ;
: align ( n -- n ) 3 + 3 inv and ;

: inc! ( addr -- ) dup @ 1 + swap ! ;
: dec! ( addr -- ) dup @ 1 - swap ! ;



( ===== Combinator ===== )

: call ( q -- ) >r ;


: if ( ? q1 q2 -- ) >r swap IF rdrop >r ELSE drop THEN ;
  # example:
  #   yes [ "hello" ] [ "world" ] if pr
  # => hello

: when   ( ? q -- ) swap IF >r ELSE drop THEN ;
: unless ( ? q -- ) swap IF drop ELSE >r THEN ;


: dip ( a q -- ... ) swap >r call r> ;
  # escape a, call q, then restore a
  # example:
  #   1 3 [ inc ] dip  => 2 3


: sip ( a q -- ... a ) over >r call r> ;
  # copy & restore a
  # eample:
  #   1 [ inc ] => 2 1


: biq ( a q1 q2 -- aq1 aq2 ) >r over >r call r> ; ( return to quotation )
  # biq - bi quotations application


: bia ( a b q -- aq bq ) swap over >r >r call r> ; ( return to quotation )
  # bia - bi arguments application


: bi* ( a b q1 q2 -- aq1 bq2 ) >r swap >r call r> ; ( return to quotation )


: bibi ( a b q1 q2 -- abq1 abq2 )
  >r >r 2dup ( a b a b | q2 q1 )
  r> swap >r ( a b a q1 | q2 b )
  swap >r    ( a b q1 | q2 b a )
  call r> r> ; ( return to quotation )


: triq ( a q1 q2 q3 -- aq1 aq2 aq3 )
  >r >r over r> swap >r ( a q1 q2 | q3 a )
  biq r> ; ( return to quotation )
  # triq - tri quotations application


: tria ( a b c q -- aq bq cq )
  swap over >r >r ( a b q | q c )
  bia r> ; ( return to quotation )
  # tria - tri arguments application


: tri* ( a b c q1 q2 q3 -- aq1 bq2 cq3 )
  >r >r swap r> swap >r ( a b q1 q2 | q3 c )
  bi* r> ; ( return to quotation )



( ===== Stdio ===== )

# port 1:stdout 2:stderr
: stdio:ready? -1 1 io ; # -- ?
: putc          0 1 io ; # c --
: getc          1 1 io ; # -- c
: stdio:port    2 1 io ; # -- p
: stdio:port!   3 1 io ; # p --


1 as: stdout
2 as: stderr


: cr    10 putc ;
: space 32 putc ;


: pr ( s -- )
  dup b@ dup 0 = [ 2drop ] ;IF
  putc 1 + AGAIN ;

: prn ( s -- ) pr cr ;


: call/port ( q p -- ) stdio:port >r stdio:port! call r> stdio:port! ;
  # call-with-port
  # call q with port p then restore previous port

: >stdout ( q -- ) stdout call/port ;
: >stderr ( q -- ) stderr call/port ;


: epr  ( s -- ) [ pr  ] >stderr ;
: eprn ( s -- ) [ prn ] >stderr ;


: die 1 HALT ;
: panic eprn die ;



( ===== File ===== )

PRIVATE
  : query    8 io ;
PUBLIC
  : file:ready?  -1 query ; # -- ?
  : file:open     0 query ; # path mode -- id ok | ng
  : file:close    1 query ; # id -- ?
  : file:read     2 query ; # buf len id -- ?
  : file:write    3 query ; # buf len id -- ?
  : file:seek     4 query ; # id offset origin -- ?
  : file:exists?  5 query ; # path -- ?
  : file:getc     6 query ; # id -- c | 0
  : file:peek     7 query ; # id -- c | 0
  : file:fullpath 8 query ; # path buf max -- ?
  : file:size     9 query ; # id -- n
  ( --- defensive --- )
  : file:open!  dup file:open [ "Can't open " epr eprn die ] nip ; # path mode -- id
  : file:close! file:close drop ; # id --
  : file:read!  file:read  IF RET THEN "Can't read" panic ;
  : file:write! file:write IF RET THEN "Can't write" panic ;
END


: putc 0 1 io ;
: atmark 64 putc ;
: foo 64 10 [ putc ] bia ;
: bar 38 10 [ putc ] bia ;
: baz [ foo ] [ bar ] if ;
: bye 0 HALT ;
: main no baz bye ;
