require: lib/locals.f

: foo { a b | c -- a+b } a b + c! c ;

1 2 foo 3 = "locals" ASSERT

( check overwrite locals )

: a 100 ;
: b 200 ;
: c 300 ;

: foo { a b | c -- a+b } a b + c! c ;
1 2 foo 3 = "overwrite" ASSERT


