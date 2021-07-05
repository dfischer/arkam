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



MARKER: <STRING>

"s:len" [
  ok
] CHECK


: scheck s:check nip ; # str max -- ?
"s:check" [
  "foo" 3 scheck not "s:check exclude null" ASSERT
  "foo" 4 scheck     "s:check include null" ASSERT

  "" 0 scheck not "s:check 0 exc.null" ASSERT
  "" 1 scheck     "s:check 0 inc.null" ASSERT

  ok
] CHECK


( ----- with buffer ----- )

256 as: len
len allot as: buf
len dec as: max

: clear buf len memclear ;


"memclear" [
  1 buf max + b!
  clear
  buf max + b@ 0 = "after memclear" ASSERT
  ok
] CHECK

: >buf clear buf swap s:append! ;

"s:append!" [
  clear
  buf "foo" s:append!
  buf "foo" s= "0+foo" ASSERT

  "foo" >buf
  buf "bar" s:append!
  buf "foobar" s= "foo+bar" ASSERT

  "foo" >buf
  buf "" s:append!
  buf "foo" s= "foo+0" ASSERT

  clear
  buf s:len 0 = "0+0" ASSERT

  ok
] CHECK


"s:append" [
  "foo" >buf
  buf "" max s:append "s:append foo+0 len" ASSERT
  buf "foo" s= "s:append foo+0" ASSERT

  clear
  buf "" max s:append "s:append 0+0" ASSERT

  "foo" >buf
  buf "bar" 6 s:append not "s:append exclude null" ASSERT
  buf "bar" 7 s:append     "s:append include null" ASSERT

  ok
] CHECK


<STRING>
