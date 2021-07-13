( for debug )
no var> verbose



# Naming and Abbrev
# x -- cross, works on target image
# m -- meta, works on metacompiler (this code)



( ===== Memo ===== )

: #TODO <IMMED>
  [ " #TODO " epr
    [ forth:take
      0  [ STOP ] ;case
      10 [ STOP ] ;case
      putc GO
    ] while
    cr
  ] >stderr
;



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
: xLIT,   2 prim, ;
: xRET,   3 prim, ;
: xJMP,  16 prim, ;
: xZJMP, 17 prim, ;
: x!,    19 prim, ;



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

: x:find ( name -- xword yes | name no )
  xlatest [ ( name xword )
    0 [ no STOP ] ;case
    2dup xname x>t s= [ nip yes STOP ] ;when
    xnext GO
  ] while
;

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


" M-                " as: meta_buf
meta_buf 2 +          as: meta_name
meta_name s:len       as: meta_len

: name>meta ( s -- buf )
  meta_len s:check [ epr panic" : too long" ] ;unless
  meta_name s:copy
  meta_buf
;

: M:
  forth:read [ panic" Meta word name required" ] ;unless
  name>meta _:
;


( for const )
var: const_link

: const_link, ( xadr -- )
  # LIT v RET link
  xhere const_link x, -> const_link
;

: patch_const ( xadr -- )
  # LIT v RET link -> LIT v JMP xadr
  const_link [ ( adr link )
    0 [ STOP ] ;case
    dup x@ >r over swap x! r>
  ] while drop
  -1 -> const_link ( done )
;

: const_done const_link -1 = ;


( for PRIVATE/PUBLIC )
: x:hide_range ( start -- end )
  # hide start < word <= end
  [ 2dup = [ 2drop STOP ] ;when
    dup x:hide! xnext GO
  ] while
;



( ===== Primitive Helper ===== )

: PRIMITIVES 1 [ drop ] ;

: PRIM: ( n closer q name: -- n+ )
  # : name <IMMED> LIT code LIT q JMP handler
  forth:read [ panic" Primitive name required" ] ;unless
  name>meta forth:create
  POSTPONE: <IMMED>
  >r over prim>code LIT, , r> LIT, , JMP,
  [ forth:mode [ drop x, ] [ nip >r ] if ] ,
  ' inc dip
  verbose [
    " prim " epr meta_name epr
    "  code " epr over .. forth:latest forth:code cell + @ .
  ] when
;

: compile_only [ panic" compile only!" ] ;



( ===== Setup/Finish ===== )

: m:finish
  const_done [ panic" do patch_const" ] ;unless
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
  word' (        forth:show!
  word' #        forth:show!
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

M: X: ( -- q ) <IMMED>
  # No meta-word will be created.
  # used for words that conflicts meta-word
  # ex. : ; IF [ <IMMED>
  forth:mode [ panic" Do not call X: in compile mode" ] ;when
  forth:read [ panic" X-Word name required" ] ;unless
  x:create drop
  yes forth:mode!
  [ xRET, xlatest x:hide! no forth:mode! ]
;

M: :
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

M: ; <IMMED> ( q -- ) >r ;

M: <IMMED> <IMMED> xlatest x:immed! ;


M: as: <IMMED> ( n name: -- )
  forth:mode [ panic" Do not call as: in compile mode" ] ;when
  forth:read [ panic" Const name required" ] ;unless
  dup
  ( x-const ) x:create drop xLIT, over x, xRET, const_link,
  ( m-const )
  forth:create POSTPONE: <IMMED>
  LIT, , JMP,
  [ forth:mode [ xLIT, x, ] when ] ,
;

M: patch_const ( xadr ) patch_const ;


M: [ <IMMED>
  forth:mode [ xJMP, xhere 0 , ] when xhere ( &back &q | &q )
  forth:mode yes forth:mode! ( &back &q mode | &q mode )
  [ xRET,
    dup forth:mode!
    [ swap xhere swap x! xLIT, x, ] when
  ]
;

M: ] <IMMED> ( q -- ) >r ;


M: IF <IMMED> ( -- &back )
  xZJMP, xhere 0 x,
;

M: ELSE <IMMED> ( &back -- &back2 )
  xJMP, xhere 0 x, swap ( &back2 &back )
  xhere swap x!
;

M: THEN <IMMED> ( &back -- )
  xhere swap x!
;


M: AGAIN <IMMED>
  xJMP, xlatest xxt x,
;


M: PRIVATE ( -- start closer )
  xlatest [ xlatest x:hide_range ]
;

M: PUBLIC ( start closer -- start end closer )
  drop xlatest ' x:hide_range
;


M: defer: ( name: -- )
  # JMP actual
  forth:read [ panic" Word name required" ] ;unless
  dup x:create m:create
  xJMP, 0 x,
;

M: -> <IMMED> ( v &code -- )
  forth:read [ panic" Word name required" ] ;unless
  x:find [ epr " ?" panic ] ;unless
  xxt
  # replace as `JMP|LIT v`
  cell + forth:mode [ xLIT, , x!, ] [ x! ] if
;

M: ' <IMMED>
  #TODO meta-tick
;


( ----- testing ----- )

m:start

42 as: answer
X: answer HALT ;

: foo 1 IF answer ELSE answer 1 + THEN HALT ;

defer: bar
' foo -> bar

[ ( no-op ) ] patch_const

m:finish

