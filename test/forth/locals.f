require: lib/locals.f

MARKER: <LOCALS>

: foo { $a $b | $c -- a+b } $a $b + $c! $c ;

1 2 foo 3 = ASSERT" locals"

<LOCALS>
