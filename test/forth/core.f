# ----- Test tools -----

ok "ASSERT" ASSERT

ok "ASSERT" ASSERT

"CHECK" [ ok ] CHECK

[ ] "clean 0-0" CLEAN
1 [ drop 0 ] "clean 1-1" CLEAN



# ( ng "COMMENT" ASSERT
( ng "COMMENT" ASSERT )



# ----- Stack -----

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



# ----- Control flow -----

: test;when   [ yes ] ;when   no ;
: test;unless [ yes ] ;unless no ;

";when" [
  yes test;when     ";when yes" ASSERT
  no  test;when not ";when no" ASSERT
  ok
] CHECK

";unless" [
  yes test;unless not ";unless yes" ASSERT
  no  test;unless     ";unless no" ASSERT
  ok
] CHECK



# ----- Forth -----

: foo [do 3 LIT, , RET, ] ;

"LIT, and RET," [ foo 3 = ] CHECK



# ----- Num -----

"clamp" [
  0 1 4 clamp 1 = "clamp under" ASSERT
  1 1 4 clamp 1 = "clamp min" ASSERT
  2 1 4 clamp 2 = "clamp middle" ASSERT
  3 1 4 clamp 3 = "clamp max" ASSERT
  4 1 4 clamp 3 = "clamp over" ASSERT
  ok
] CHECK

"within?" [
  0 1 4 within? not "within lt" ASSERT
  4 1 4 within? not "within gt" ASSERT

  1 1 4 within? "within min limit" ASSERT
  2 1 4 within? "within mid" ASSERT
  3 1 4 within? "within max limit" ASSERT
  ok
] CHECK



# ----- COVER -----

123 as: x

COVER
  234 as: x
SHOW
  123 as: y
  x 234 = "in module" ASSERT
END

x 123 = "out of module" ASSERT
y 123 = "module exposed" ASSERT


( ----- no exposed ----- )

COVER
  234 as: x
  x 234 = "in module - no exposed" ASSERT
END

x 123 = "out of module - no exposed" ASSERT


( ----- no content ----- )
COVER END



# ----- String -----

"s= same" [ "foo" "foo" s=     ] CHECK
"s= diff" [ "foo" "bar" s= not ] CHECK

"s>dec positive" [ "123"  s>dec IF  123 = ELSE no THEN ] CHECK
"s>dec negative" [ "-123" s>dec IF -123 = ELSE no THEN ] CHECK
"s>dec ng1" [ " "  s>dec not ] CHECK
"s>dec ng2" [ "-" s>dec not ] CHECK
"s>dec ng3" [ "0a" s>dec not ] CHECK


"s:len" [
  ok
] CHECK


: scheck s:check nip ; # str max -- ?
"s:check" [
  "foo" 3 scheck not "s:check exclude null" ASSERT
  "foo" 4 scheck     "s:check include null" ASSERT

  " " 0 scheck not "s:check 0 exc.null" ASSERT
  "" 1 scheck     "s:check 0 inc.null" ASSERT

  ok
] CHECK


"s:start?" [
  "foo" "foo"  s:start?     "s:start foo/foo" ASSERT
  "foo" "f"    s:start?     "s:start foo/f" ASSERT
  "foo" ""    s:start?     "s:start foo/0" ASSERT
  " "   " "    s:start?     "s:start 0/0" ASSERT
  "foo" "fooo" s:start? not "s:start foo/fooo" ASSERT
  " "   " foo" s:start? not "s:start 0/foo" ASSERT
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

"memcopy" [
  clear
  "foo" >buf
  "bar" buf 3 + 4 memcopy
  buf "foobar" s= "memcopy" ASSERT

  "xxx" buf 3 + 0 memcopy
  buf "foobar" s= "no memcopy" ASSERT
  ok
] CHECK

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
  buf " "max s:append "s:append 0+0" ASSERT

  "foo" >buf
  buf "bar" 6 s:append not "s:append exclude null" ASSERT
  buf "bar" 7 s:append     "s:append include null" ASSERT

  ok
] CHECK


"s:each_line!" [
  "foo" >buf
  buf [ "foo" s= "foo 1" ASSERT ] s:each_line!

  "" >buf
  buf [ "do not reach here" panic ] s:each_line!

  "foo\nfoo" >buf
  buf [ "foo" s= "foo 2" ASSERT ] s:each_line!

  "foo\nfoo\n" >buf
  buf [ "foo" s= "ignore trailing newline" ASSERT ] s:each_line!

  ok
] CHECK



# ----- Combinator -----

"dip 1" [ 1 2 [ inc ] dip + ( => 2 2 + ) 4 = ] CHECK


"sip 1" [ 1 [ inc ] sip + ( => 2 1 + ) 3 = ] CHECK


"biq 1" [ 1 [ 1 + ] [ 2 + ] biq + ( => 2 3 +     ) 5 = ] CHECK
"biq 2" [ 1 [ 1   ] [ + + ] biq   ( => 1 1 1 + + ) 3 = ] CHECK


"bia 1" [ 1 2 [ inc ] bia + ( => 2 3 + )     5 = ] CHECK
"bia 2" [ 1 2 3 [ + ] bia   ( => 1 2 + 3 + ) 6 = ] CHECK


"bi* 1" [ 1 2 [ 1 + ] [ 2 + ] bi* + ( => 2 4 + )     6 = ] CHECK
"bi* 2" [ 2 3 [ 1   ] [ + + ] bi*   ( => 2 1 3 + + ) 6 = ] CHECK


"bibi 1" [ 1 2 [ + ] [ 1 + + ] bibi + ( => 3 4 + ) 7 = ] CHECK


"triq 1" [ 1 [ 1 + ] [ 2 + ] [ 3 + ] triq + + ( => 2 3 4 + + ) 9 = ] CHECK


"tria 1" [ 1 2 3 [ inc ] tria + + ( => 2 3 4 + + ) 9 = ] CHECK


"tri* 1" [ 1 2 3 [ inc ] [ inc ] [ inc ] tri* + + ( => 2 3 4 + + ) 9 = ] CHECK



# ----- Var -----

var: x

"var" [
  yes x!
  x "var set/get" ASSERT

  123 x!
  var' x @ 123 = "var addr" ASSERT

  234 ' x! call
  x 234 = "var setter reference" ASSERT

  ok
] CHECK

"var update" [
  123 x!

  var' x inc!
  x 124 = "&var inc!" ASSERT

  var' x dec!
  x 123 = "&var dec!" ASSERT

  var' x [ inc ] update!
  x 124 = "&var update!" ASSERT

  ok
] CHECK



# ----- Char -----

64 as: atmark

"char:" [
  CHAR: @ atmark = "char: in compile mode" ASSERT
  ok
] CHECK

CHAR: @ atmark = "char: in run mode" ASSERT



# ----- Struct -----

STRUCT: foo
  3 field: a
  cell field: b
  cell: c
END

"struct" [
  foo 11 = "struct size" ASSERT

  foo a  foo       = "struct 1st field" ASSERT
  foo b  foo 3 +   = "struct 2nd field" ASSERT
  foo c  foo b 4 + = "struct 3rd field" ASSERT

  ok
] CHECK


STRUCT: %foo
  cell: .bar :access
END

%foo allot as: foo

"struct accessor" [
  123 foo bar!
  foo bar  123  = "get/set" ASSERT
ok ] CHECK


# ----- Shuffle -----

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

sum 45 = "shuffle1" ASSERT
sum 45 = "shuffle1" ASSERT
sum 45 = "shuffle1" ASSERT
sum 45 = "shuffle1" ASSERT
sum 45 = "shuffle1" ASSERT
