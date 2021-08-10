require: lib/locals.f

MARKER: <LOCALS>

: foo { a b | c -- a+b } a b + c! c ;

1 2 foo 3 = ASSERT" locals"

( check overwrite locals )

: a 100 ;
: b 200 ;
: c 300 ;

: foo { a b | c -- a+b } a b + c! c ;
1 2 foo 3 = ASSERT" overwrite"

<LOCALS>
