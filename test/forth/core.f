MARKER: <TEST-TOOLS>

ok ASSERT" ASSERT"

ok ASSERT" ASSERT\""

" CHECK" [ ok ] CHECK

[ ] CLEAN" clean 0-0"
1 [ drop 0 ] CLEAN" clean 1-1"

<TEST-TOOLS>



# ( ng ASSERT" COMMENT"
( ng ASSERT" COMMENT" )



MARKER: <STACK>

" tuck" [ 1 2 tuck 2drop 2 = ] CHECK

" ?dup 0" [ 0 ?dup 0 = ] CHECK
" ?dup 1" [ 1 ?dup + 2 = ] CHECK

" pullup" [
  1 2 3 pullup
  1 = ASSERT" pullup TOS"
  3 = ASSERT" pullup 2nd"
  2 = ASSERT" pullup 3rd"
  ok
] CHECK

" pushdown" [
  1 2 3 pushdown
  2 = ASSERT" pushdown TOS"
  1 = ASSERT" pushdown 2nd"
  3 = ASSERT" pushdown 3rd"
  ok
] CHECK

<STACK>



MARKER: <CONTROLFLOW>

: test;when   [ yes ] ;when   no ;
: test;unless [ yes ] ;unless no ;

" ;when" [
  yes test;when     ASSERT" ;when yes"
  no  test;when not ASSERT" ;when no"
  ok
] CHECK

" ;unless" [
  yes test;unless not ASSERT" ;unless yes"
  no  test;unless     ASSERT" ;unless no"
  ok
] CHECK

<CONTROLFLOW>



MARKER: <FORTH>

: foo [do 3 LIT, , RET, ] ;

" LIT, and RET," [ foo 3 = ] CHECK

<FORTH>



MARKER: <NUM>

" clamp" [
  0 1 4 clamp 1 = ASSERT" clamp under"
  1 1 4 clamp 1 = ASSERT" clamp min"
  2 1 4 clamp 2 = ASSERT" clamp middle"
  3 1 4 clamp 3 = ASSERT" clamp max"
  4 1 4 clamp 3 = ASSERT" clamp over"
  ok
] CHECK

" within?" [
  0 1 4 within? not ASSERT" within lt"
  4 1 4 within? not ASSERT" within gt"

  1 1 4 within? ASSERT" within min limit"
  2 1 4 within? ASSERT" within mid"
  3 1 4 within? ASSERT" within max limit"
  ok
] CHECK

<NUM>



MARKER: <COVER>

123 as: x

COVER
  234 as: x
SHOW
  123 as: y
  x 234 = ASSERT" in module"
END

x 123 = ASSERT" out of module"
y 123 = ASSERT" module exposed"


( ----- no exposed ----- )

COVER
  234 as: x
  x 234 = ASSERT" in module - no exposed"
END

x 123 = ASSERT" out of module - no exposed"


( ----- no content ----- )
COVER END

<COVER>



MARKER: <STRING>

" s= same" [ " foo" " foo" s=     ] CHECK
" s= diff" [ " foo" " bar" s= not ] CHECK

" s>dec positive" [ " 123"  s>dec IF  123 = ELSE no THEN ] CHECK
" s>dec negative" [ " -123" s>dec IF -123 = ELSE no THEN ] CHECK
" s>dec ng1" [ " "  s>dec not ] CHECK
" s>dec ng2" [ " -" s>dec not ] CHECK
" s>dec ng3" [ " 0a" s>dec not ] CHECK


" s:len" [
  ok
] CHECK


: scheck s:check nip ; # str max -- ?
" s:check" [
  " foo" 3 scheck not ASSERT" s:check exclude null"
  " foo" 4 scheck     ASSERT" s:check include null"

  " " 0 scheck not ASSERT" s:check 0 exc.null"
  " " 1 scheck     ASSERT" s:check 0 inc.null"

  ok
] CHECK


" s:start?" [
  " foo" " foo"  s:start?     ASSERT" s:start foo/foo"
  " foo" " f"    s:start?     ASSERT" s:start foo/f"
  " foo" " "     s:start?     ASSERT" s:start foo/0"
  " "    " "     s:start?     ASSERT" s:start 0/0"
  " foo" " fooo" s:start? not ASSERT" s:start foo/fooo"
  " "    " foo"  s:start? not ASSERT" s:start 0/foo"
  ok
] CHECK


( ----- with buffer ----- )

256 as: len
len allot as: buf
len dec as: max

: clear buf len memclear ;


" memclear" [
  1 buf max + b!
  clear
  buf max + b@ 0 = ASSERT" after memclear"
  ok
] CHECK

: >buf clear buf swap s:append! ;

" memcopy" [
  clear
  " foo" >buf
  " bar" buf 3 + 4 memcopy
  buf " foobar" s= ASSERT" memcopy"

  " xxx" buf 3 + 0 memcopy
  buf " foobar" s= ASSERT" no memcopy"
  ok
] CHECK

" s:append!" [
  clear
  buf " foo" s:append!
  buf " foo" s= ASSERT" 0+foo"

  " foo" >buf
  buf " bar" s:append!
  buf " foobar" s= ASSERT" foo+bar"

  " foo" >buf
  buf " " s:append!
  buf " foo" s= ASSERT" foo+0"

  clear
  buf s:len 0 = ASSERT" 0+0"

  ok
] CHECK


" s:append" [
  " foo" >buf
  buf " " max s:append ASSERT" s:append foo+0 len"
  buf " foo" s= ASSERT" s:append foo+0"

  clear
  buf " " max s:append ASSERT" s:append 0+0"

  " foo" >buf
  buf " bar" 6 s:append not ASSERT" s:append exclude null"
  buf " bar" 7 s:append     ASSERT" s:append include null"

  ok
] CHECK


" s:each_line!" [
  " foo" >buf
  buf [ " foo" s= ASSERT" foo 1" ] s:each_line!

  " " >buf
  buf [ panic" do not reach here" ] s:each_line!

  " foo\nfoo" >buf
  buf [ " foo" s= ASSERT" foo 2" ] s:each_line!

  " foo\nfoo\n" >buf
  buf [ " foo" s= ASSERT" ignore trailing newline" ] s:each_line!

  ok
] CHECK

<STRING>



MARKER: <COMBINATOR>

" dip 1" [ 1 2 [ inc ] dip + ( => 2 2 + ) 4 = ] CHECK


" sip 1" [ 1 [ inc ] sip + ( => 2 1 + ) 3 = ] CHECK


" biq 1" [ 1 [ 1 + ] [ 2 + ] biq + ( => 2 3 +     ) 5 = ] CHECK
" biq 2" [ 1 [ 1   ] [ + + ] biq   ( => 1 1 1 + + ) 3 = ] CHECK


" bia 1" [ 1 2 [ inc ] bia + ( => 2 3 + )     5 = ] CHECK
" bia 2" [ 1 2 3 [ + ] bia   ( => 1 2 + 3 + ) 6 = ] CHECK


" bi* 1" [ 1 2 [ 1 + ] [ 2 + ] bi* + ( => 2 4 + )     6 = ] CHECK
" bi* 2" [ 2 3 [ 1   ] [ + + ] bi*   ( => 2 1 3 + + ) 6 = ] CHECK


" bibi 1" [ 1 2 [ + ] [ 1 + + ] bibi + ( => 3 4 + ) 7 = ] CHECK


" triq 1" [ 1 [ 1 + ] [ 2 + ] [ 3 + ] triq + + ( => 2 3 4 + + ) 9 = ] CHECK


" tria 1" [ 1 2 3 [ inc ] tria + + ( => 2 3 4 + + ) 9 = ] CHECK


" tri* 1" [ 1 2 3 [ inc ] [ inc ] [ inc ] tri* + + ( => 2 3 4 + + ) 9 = ] CHECK

<COMBINATOR>



MARKER: <VAR>

var: x

" var" [
  yes x!
  x ASSERT" var set/get"

  123 x!
  var' x @ 123 = ASSERT" var addr"

  234 ' x! call
  x 234 = ASSERT" var setter reference"

  ok
] CHECK

" var update" [
  123 x!

  var' x inc!
  x 124 = ASSERT" &var inc!"

  var' x dec!
  x 123 = ASSERT" &var dec!"

  var' x [ inc ] update!
  x 124 = ASSERT" &var update!"

  ok
] CHECK

<VAR>



MARKER: <CHAR>

64 as: atmark

" char:" [
  CHAR: @ atmark = ASSERT" char: in compile mode"
  ok
] CHECK

CHAR: @ atmark = ASSERT" char: in run mode"

<CHAR>



MARKER: <STRUCT>

STRUCT foo
  3 field: a
  cell field: b
  cell: c
END

" struct" [
  foo 11 = ASSERT" struct size"

  foo a  foo       = ASSERT" struct 1st field"
  foo b  foo 3 +   = ASSERT" struct 2nd field"
  foo c  foo b 4 + = ASSERT" struct 3rd field"

  ok
] CHECK

<STRUCT>




MARKER: <SHUFFLE>

var: xs here xs!
0 ,
1 ,
2 ,
3 ,
4 ,
5 ,
6 ,
7 ,
8 ,
9 ,

: sum
    xs 10 shuffle
    0 10 [ cells xs + @ + ] for
;

sum 45 = ASSERT" shuffle1"
sum 45 = ASSERT" shuffle1"
sum 45 = ASSERT" shuffle1"
sum 45 = ASSERT" shuffle1"
sum 45 = ASSERT" shuffle1"

<SHUFFLE>
