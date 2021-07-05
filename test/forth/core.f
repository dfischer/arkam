require: lib/core.f



MARKER: <TEST-TOOLS>

ok "ASSERT" ASSERT

"CHECK" [ ok ] CHECK

<TEST-TOOLS>



# ( ng "COMMENT" ASSERT
( ng "COMMENT" ASSERT )



MARKER: <STACK>

"tuck" [ 1 2 tuck 2drop 2 = ] CHECK

"?dup 0" [ 0 ?dup 0 = ] CHECK
"?dup 1" [ 1 ?dup + 2 = ] CHECK

"pullup" [
  1 2 3 pullup
  1 = "pullup TOS" ASSERT
  3 = "pullup 2nd" ASSERT
  2 = "pullup 3rd" ASSERT
  ok
] CHECK

"pushdown" [
  1 2 3 pushdown
  2 = "pushdown TOS" ASSERT
  1 = "pushdown 2nd" ASSERT
  3 = "pushdown 3rd" ASSERT
  ok
] CHECK

<STACK>



MARKER: <FORTH>

: foo [do 3 LIT, RET, ] ;

"LIT, and RET," [ foo 3 = ] CHECK

<FORTH>
