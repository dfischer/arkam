# =========================
#    Forth Meta Compiler
# ========================
#
# This compiles lib/core.f to Forth base image file.
#
# === Naming and Abbrev
# x -- cross, works on target image
# m -- meta, works on metacompiler (this code)
#
# === Summary
# 1. Create cross-dictionary and define helper words
# 2. Define meta-words that can be called in metacompile phase
#   - Primitives (ex. dup, swap, !, @, >r)
#   - Syntax (ex. :, ;, IF, [, PRIVATE)
# 3. Hide all words except meta-words
# 4. Start metacompile by including lib/core.f
# 5. Patch some addresses and save image



( for debug )
no var> verbose



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
    " wb" file:open! id!
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
#  | next
#  | flags
#  | &name
#  | xt(&code)
#  |-----
#  | code ...
#
# flags:
0x01 as: immed_flag
0x02 as: hidden_flag


: xlatest  adr_xlatest x@ ;
: xlatest! adr_xlatest x! ;

: xnext! x! ;
: xnext  x@ ;

: xflags! cell + x! ;
: xflags  cell + x@ ;
: xon!  over xflags swap on  swap xflags! ;
: xoff! over xflags swap off swap xflags! ;
: x:hide!   hidden_flag xon!       ;  # xword --
: x:show!   hidden_flag xoff!      ;  # xword --
: x:hidden? xflags hidden_flag and ;  # xword -- ?
: x:immed!  immed_flag xon!        ;  # xword --

: xname! 2 cells + x! ;
: xname  2 cells + x@ ;

: xxt!   3 cells + x! ;
: xxt    3 cells + x@ ;

: x:find ( name -- xword yes | name no )
  xlatest [ ( name xword )
    0 [ no STOP ] ;case
    2dup xname x>t s= [ nip yes STOP ] ;when
    xnext GO
  ] while
;

: x:create ( name -- xword )
  xhere:align! xhere swap x:sput ( &name )
  ( next  ) xhere:align! xhere xlatest x, xlatest!
  ( flags ) 0 x,
  ( name  ) x,
  ( xt    ) xhere cell + x,
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

: <run_only> <IMMED>
  POSTPONE: <IMMED>
  LIT, forth:latest forth:name 2 + ,
  [ forth:mode [ " Do not compile: " epr panic ] [ drop ] if ] ,
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
    dup x@ >r over swap x! r> GO
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

var: m:image_name

: m:finish
  m:image_name [ panic" No image name" ] ;unless
  const_done [ panic" do patch_const" ] ;unless
  xlatest xxt entrypoint!
  verbose [ " Turnkey: " epr xlatest xname x>t eprn ] when
  m:image_name save
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
  word' include: forth:show!
  ' m:handle_num -> forth:handle_num
  verbose [
    " --Meta Words----- " prn forth:words
  ] when
;

: m:start [do LIT, forth:latest , ] m:install ;

: metacompile
  opt:read! [ panic" Image name required" ] ;unless -> m:image_name
  m:start
  " lib/core.f" include
  " doconst" x:find [ panic" doconst definition not found" ] ;unless
  xxt patch_const
  m:finish
;


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

M: X: ( -- q ) <run_only>
  # No meta-word will be created.
  # used for words that conflicts meta-word
  # ex. : ; IF [ <IMMED>
  forth:mode [ panic" Do not call X: in compile mode" ] ;when
  forth:read [ panic" X-Word name required" ] ;unless
  x:create drop
  yes forth:mode!
  xlatest x:hide!
  [ xRET, xlatest x:show! no forth:mode! ]
;

M: : <run_only>
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


M: as: ( n name: -- ) <run_only>
  forth:mode [ panic" Do not call as: in compile mode" ] ;when
  forth:read [ panic" Const name required" ] ;unless
  dup
  ( x-const ) x:create drop xLIT, over x, xJMP, const_link, xlatest x:immed!
  ( m-const )
  forth:create POSTPONE: <IMMED>
  LIT, , JMP,
  [ forth:mode [ xLIT, x, ] when ] ,
;

M: patch_const ( xadr ) <run_only> patch_const ;


M: [ <IMMED>
  forth:mode [ xJMP, xhere 0 x, ] when xhere ( &back &q | &q )
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


M: PRIVATE ( -- xstart mstart closer ) <run_only>
  xlatest forth:latest [ forth:latest forth:hide_range xlatest x:hide_range ]
;

M: PUBLIC ( xstart mstart closer -- xstart xend mstart mend closer ) <run_only>
  drop xlatest swap forth:latest [ forth:hide_range x:hide_range ]
;

M: END ( closer -- ) <IMMED> >r ;


M: defer: ( name: -- ) <run_only>
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
  cell + forth:mode [ xLIT, x, x!, ] [ x! ] if
;


M: ' <IMMED>
  forth:read [ panic" Word name required" ] ;unless
  x:find [ epr "  ?" panic ] ;unless
  xxt
  forth:mode [ xLIT, x, ] when
;


M: var> <run_only>
  forth:read [ panic" Var name required" ] ;unless
  30 s:check [ epr panic" : too long var name" ] ;unless
  dup >r
  dup x:create m:create
  xLIT, xhere swap x, xRET, r>
  dup " !" s:append!
  dup x:create m:create
  xLIT, x, x!, xRET,
;

M: var: <run_only> 0 POSTPONE: M-var> ;


M: CHAR: <IMMED>
  forth:read [ panic" A character required" ] ;unless
  dup b@ dup CHAR: \\ = [ drop inc
    [ [ inc ] [ b@ ] biq ] c:escaped
    [ panic" Escape sequence required" ] ;unless
  ] when nip
  forth:mode [ xLIT, x, ] when
;


M: " <IMMED>
  forth:mode [ xJMP, xhere 0 x, xhere swap ] [ xhere ] if
  [ forth:take
    0  [ panic" Unclosed string" STOP ] ;case
    CHAR: " [ STOP ] ;case
    dup CHAR: \\ = [
      drop ' forth:take c:escaped
      [ panic" Escape sequence required" STOP ] ;unless
      bx, GO
    ] ;when
    bx, GO
  ] while
  0 bx, xhere:align!
  forth:mode [ xhere swap x! xLIT, x, ] when
;



PRIVATE

  xhere 0 x, as: link

PUBLIC

  link as: init:link

  M: >init <run_only>
    xhere link x@ x, link x!
    x,
  ;

  M: init:run <IMMED>
    " init:run" x:find [ drop panic" Define init:run" ] ;unless
    xxt x,
  ;

END



( ----- debug ----- )

M: ?H <IMMED> " HERE" prn ;

M: ?STACK <IMMED> ?stack ;



( ####################### )
( ## Start Metacompile ## )
( ####################### )

metacompile
