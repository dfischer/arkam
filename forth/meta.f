( for debug )
no var> verbose



# Naming and Abbrev
# x -- cross, works on target image
# m -- meta, works on metacompiler (this code)



( ===== Image area and There pointer ===== )

: kilo 1000 * ;
256 kilo        as: image_max
image_max allot as: there


( memory layout )

0x04 as: adr_start
0x08 as: adr_here
0x0C as: adr_xlatest
0x10 as: adr_begin


( relative pointer )

var: xhere

: x>t there + ; # &x -- &there
: t>x there - ; # &there -- &x

: x@  x>t @ ;
: x!  x>t ! ;
: bx@ x>t b@ ;
: bx! x>t b! ;

: xhere! ( xadr -- )
  dup 0             <  [ .. panic" invalid xhere" ] ;when
  dup image_max - 0 >= [ .. panic" invalid xhere" ] ;when
  dup -> xhere
  adr_here x!
;


: xhere:align! xhere align xhere! ;

: x,  xhere x!  xhere cell + xhere! ;
: bx, xhere bx! xhere inc    xhere! ;



( ----- initialize ----- )

adr_begin xhere!


( ----- string ----- )

: x:sput ( s -- )
  dup s:len inc >r xhere x>t s:copy r> xhere + xhere! xhere:align!
;



( ===== Save Image ===== )

: entrypoint! ( xadr -- ) adr_start x! ;

: image_size xhere x>t there - ;


PRIVATE

  var: id

PUBLIC

  : save ( fname -- )
    " wb" file:open! -> id
    there image_size id file:write!
    id file:close!
  ;

  : save: ( fname: -- )
    forth:read [ panic" Image name required" ] unless
    save
  ;

END



( ===== xPrimitives ===== )

: prim>code 1 << 1 or ;
: prim, prim>code x, ;
: xHALT, 1 prim, ;
: xLIT,  2 prim, ;
: xRET,  3 prim, ;



( ===== Cross&Meta Dictionary ===== )

# Cross Dictionary
#  | name ...
#  | ( 0alined )
#  | next | hidden? | immed? ( least 2 bit )
#  | &name
#  | xt(&code)
#  |-----
#  | code ...

: xlatest  adr_xlatest x@ ;
: xlatest! adr_xlatest x! ;

: xname! cell + x! ;
: xname  cell + x@ ;

: xxt!   2 cells + x! ;
: xxt    2 cells + x@ ;

: x:create ( name -- xword )
  xhere:align! xhere swap x:sput ( &name )
  ( next ) xhere:align! xhere xlatest x, xlatest!
  ( name ) x,
  ( xt   ) xhere cell + x,
  xlatest
;

: m:create ( name xword -- )
  # create meta word
  over forth:create POSTPONE: <IMMED>
  swap LIT, , LIT, , JMP, [
    forth:mode [ nip xxt x, ] [
      drop " Attempt to call in meta: " epr panic
    ] if
  ] ,
;



( ----- testing ----- )

xhere entrypoint!
xLIT, 42 x, xHALT,
save: out/forth2.ark

