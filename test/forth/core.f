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



MARKER: <NUM>

"clamp" [
  0 1 4 clamp 1 = "clamp under"  ASSERT
  1 1 4 clamp 1 = "clamp min"    ASSERT
  2 1 4 clamp 2 = "clamp middle" ASSERT
  3 1 4 clamp 3 = "clamp max"    ASSERT
  4 1 4 clamp 3 = "clamp over"   ASSERT
  ok
] CHECK

<NUM>



MARKER: <MODULE>

123 as: x

MODULE
  234 as: x
---EXPOSE---
  123 as: y
  x 234 = "in module" ASSERT
END

x 123 = "out of module" ASSERT
y 123 = "module exposed" ASSERT


( ----- no exposed ----- )

MODULE
  234 as: x
  x 234 = "in module - no exposed" ASSERT
END

x 123 = "out of module - no exposed" ASSERT


( ----- no content ----- )
MODULE END

<MODULE>
