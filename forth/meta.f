( for debug )
yes var> verbose



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

0x01 as: immed_flag
0x02 as: hidden_flag
0x03 as: flags

: xlatest  adr_xlatest x@ ;
: xlatest! adr_xlatest x! ;

: x:hide!   hidden_flag on!  ;    # xword --
: x:show!   hidden_flag off! ;    # xword --
: x:hidden? x@ hidden_flag and ;  # xword -- ?
: x:immed!  immed_flag on! ;      # xword --

: xnext! x! ;
: xnext  x@ flags off ;

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



( ===== Primitive Helper ===== )

" M-            " as: prim_buf
prim_buf 2 +      as: prim_name

: PRIMITIVES 0 [ drop ] ;

: PRIM: ( n closer q name: -- n+ )
  # : name <IMMED> LIT code LIT q JMP handler
  forth:read [ panic" Primitive name required" ] ;unless
  prim_name s:copy
  prim_buf forth:create POSTPONE: <IMMED>
  >r over prim>code LIT, , r> LIT, , JMP,
  [ forth:mode [ drop x, ] [ nip >r ] if ] ,
  ' inc dip
  verbose [
    " prim " epr prim_name epr
    "  code " epr over .. forth:latest forth:code cell + @ .
  ] when
;

: compile_only [ panic" compile only!" ] ;



( ===== Setup/Finish ===== )

: m:finish
  xlatest xxt entrypoint!
  " out/forth2.ark" save
;

: m:handle_num ( n -- )
  forth:mode [ xLIT, x, ] [ ( n -- n ) ] if
;

: m:reveal ( start -- )
  # reveal M-foo to foo
  forth:latest [
    0    [ STOP ] ;case
    over [ STOP ] ;case
    dup forth:name " M-" s:start? [
      dup forth:name 2 + over forth:name!
    ] when
    forth:next GO
  ] while drop
;

: m:hide ( start -- )
  # hide words before &start
  [ 0 [ STOP ] ;case
    dup forth:hide!
    forth:next GO
  ] while
;

: m:install ( meta_start -- )
  dup m:hide m:reveal
  word' m:finish forth:show!
  ' m:handle_num -> forth:handle_num
  verbose [
    " --Meta Words----- " prn forth:words
  ] when
;

: m:start [do LIT, forth:latest , ] m:install ;



( ###################### )
( ##### Meta Words ##### )
( ###################### )


( ===== Meta Primitive word ===== )

PRIMITIVES

  [      ] PRIM: NOOP
  [ HALT ] PRIM: HALT
  compile_only PRIM: LIT
  compile_only PRIM: RET

  [ dup  ] PRIM: dup
  [ drop ] PRIM: drop
  [ swap ] PRIM: swap
  [ over ] PRIM: over

  [ +    ] PRIM: +
  [ -    ] PRIM: -
  [ *    ] PRIM: *
  [ /mod ] PRIM: /mod

  [ =  ] PRIM: =
  [ != ] PRIM: !=
  [ >  ] PRIM: >
  [ <  ] PRIM: <

  compile_only PRIM: JMP
  compile_only PRIM: ZJMP

  [ @  ] PRIM: @
  [ !  ] PRIM: !
  [ b@ ] PRIM: b@
  [ b! ] PRIM: b!

  [ and  ] PRIM: and
  [ or   ] PRIM: or
  [ inv  ] PRIM: inv
  [ xor  ] PRIM: xor
  [ lsft ] PRIM: lsft
  [ asft ] PRIM: asft

  [ io ] PRIM: io

  compile_only PRIM: >r
  compile_only PRIM: r>
  compile_only PRIM: rdrop

  [ sp  ] PRIM: sp
  [ sp! ] PRIM: sp!
  [ rp  ] PRIM: rp
  [ rp! ] PRIM: rp!

END



( ===== Meta Syntax Word ===== )

: M-:
  forth:read [ panic" Word name required" ] ;unless
  dup x:create m:create
  xlatest x:hide!
  forth:latest  forth:hide!
  yes forth:mode!
  [
    xRET,
    xlatest x:show!
    forth:latest forth:show!
    no forth:mode!
  ]
;

: M-; <IMMED> ( q -- ) >r ;



( ----- testing ----- )

m:start
: foo 42 HALT ;
m:finish

