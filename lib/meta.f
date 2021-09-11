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
#   - Syntax (ex. :, ;, IF, [, COVER)
# 3. Hide all words except meta-words
# 4. Start metacompile by including lib/core.f
# 5. Patch some addresses and save image

[core] EDIT LEXI REFER
  lexicon: META
  lexicon: CROSS-ROOT
  lexicon: CROSS-CORE
  lexicon: [metacompiler]

[metacompiler] EDIT
LEXI [metacompiler] [forth] [file] REFER



( for debug )
no var> verbose



( ===== Memo ===== )

: #TODO <IMMED>
  [ "#TODO " epr
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
256 kilo        as: image-max
image-max allot as: there


( memory layout )

0x04 as: adr-start
0x08 as: adr-here
0x0C as: adr-lexicons   ( lexicon order )
0x10 as: adr-lexisp ( lexicon stack pointer )
0x14 as: adr-current ( defining lexicon )
0x18 as: adr-begin


( relative pointer )

var: xhere

: x>t there + ; # &x -- &there
: t>x there - ; # &there -- &x

: x@  x>t @ ;
: x!  x>t ! ;
: bx@ x>t b@ ;
: bx! x>t b! ;

: xhere! ( xadr -- )
  dup 0             <  [ .. "invalid xhere" panic ] ;when
  dup image-max - 0 >= [ .. "invalid xhere" panic ] ;when
  dup -> xhere
  adr-here x!
;


: xhere:align! xhere align xhere! ;

: x,  xhere x!  xhere cell + xhere! ;
: bx, xhere bx! xhere inc    xhere! ;

: xallot ( n -- addr ) xhere tuck + xhere! ;



( ----- initialize ----- )

adr-begin xhere!


( ----- string ----- )

: x:sput ( s -- )
  dup s:len inc >r xhere x>t s:copy r> xhere + xhere! xhere:align!
;



( ===== Save Image ===== )

: entrypoint! ( xadr -- ) adr-start x! ;

: image-size xhere x>t there - ;


COVER

  var: id

SHOW

  : save ( fname -- )
    "wb" file:open! id!
    there image-size id file:write!
    id file:close!
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

# Cross Lexicon
# | name...
# |----- ( 0alined )
# | latest
# | name
# | hashtable...

: xlexis  adr-lexicons x@ ;
: xlexis! adr-lexicons x! ;
: xlexisp  adr-lexisp x@ ;
: xlexisp! adr-lexisp x! ;
: xcurrent  adr-current x@ ;
: xcurrent! adr-current x! ;
: xedit xcurrent! ;

16 cells as: xlexi:size
xlexi:size xallot xlexis!
xlexis xlexisp!

16 dup as: hashd-len
cells as: hashd-size

: xlexi:new ( -- adr )
  xhere:align! xhere
  0 x, ( latest )
  0 x, ( name )
  hashd-len [ 0 x, ] times ( hashdict )
;

: xlexi:latest  ( lexi -- word ) x@ ;
: xlexi:latest! ( word lexi -- ) x! ;
: xlexi:name    ( lexi -- name ) cell + x@ ;
: xlexi:name!   ( name lexi -- ) cell + x! ;
: xlexi:hashd   ( lexi -- adr  ) 2 cells + ;

: xlexi:create ( name -- adr )
  xhere swap x:sput ( name )
  xlexi:new tuck xlexi:name!
;

: xlexi:each ( q -- ) # q: xlexi --
  xlexisp cell - [ ( q sp )
    dup xlexis < [ 2drop STOP ] ;when
    2dup >r >r x@ swap call
    r> r> cell - GO
  ] while
;

: xalso ( lexi -- ) xlexisp x! xlexisp cell + xlexisp! ;
: xprevious ( -- ) xlexisp cell - xlexisp! ;
: xdefinitions ( -- ) xlexisp cell - x@ xcurrent! ;

: xcontext 0 [ ( no-op ) ] xlexi:each ;
: xorder ( 0 xlexi ... )
  xlexis xlexisp! [ ?dup [ xalso GO ] [ STOP ] if ] while
;

"[core]" xlexi:create as: xlexi-core
"[root]" xlexi:create as: xlexi-root

xlexi-root xalso
xlexi-core xalso
xlexi-core xcurrent!

: xonly ( -- ) xlexis xlexisp! xlexi-root xalso ;

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
0x01 as: immed-flag
0x02 as: hidden-flag


: xlatest  xcurrent xlexi:latest  ;
: xlatest! xcurrent xlexi:latest! ;

: xnext! x! ;
: xnext  x@ ;

: xflags! cell + x! ;
: xflags  cell + x@ ;
: xon!  over xflags swap on  swap xflags! ;
: xoff! over xflags swap off swap xflags! ;
: x:hide!   hidden-flag xon!       ;  # xword --
: x:show!   hidden-flag xoff!      ;  # xword --
: x:hidden? xflags hidden-flag and ;  # xword -- ?
: x:immed!  immed-flag xon!        ;  # xword --

: xname! 2 cells + x! ;
: xname  2 cells + x@ ;

: xxt!   3 cells + x! ;
: xxt    3 cells + x@ ;

: x:hashd-link ( xlexi s -- xlink )
  s:hash abs hashd-len mod cells ( offset )
  swap xlexi:hashd +
;

: x:put-hashd ( xlexi xword -- )
  tuck xname x>t x:hashd-link ( xword xlink )
  2dup x@ swap xnext! x!
;

: x:find-in ( name lexi -- xword yes | name no )
  over x:hashd-link x@ [ ( name word )
    0 [ no STOP ] ;case
    2dup xname x>t s= [ nip yes STOP ] ;when
    xnext GO
  ] while
;

: x:find ( name -- xword yes | name no )
  xlexisp cell - swap [ ( sp name )
    over xlexis < [ nip no STOP ] ;when
    over x@ x:find-in [ nip yes STOP ] [ [ cell - ] dip GO ] if
  ] while
;

: x:create ( name -- xword )
  xhere:align! xhere swap x:sput ( &name )
  xhere:align! xhere xlatest!
  ( next  ) 0 x,
  ( flags ) 0 x,
  ( name  ) x,
  ( xt    ) xhere cell + x,
  ( hashd ) xcurrent xlatest x:put-hashd
  xlatest
;

: m:create ( name xword -- )
  # create meta word
  over forth:create POSTPONE: <IMMED>
  swap LIT, , LIT, , JMP, [
    forth:mode [ nip xxt x, ] [
      drop "Attempt to call in meta: " epr panic
    ] if
  ] ,
;


: meta? ( s -- ? ) META forth:find-in nip ;

: <run-only> <IMMED>
  POSTPONE: <IMMED>
  LIT, forth:latest forth:name 2 + ,
  [ forth:mode [ "Do not compile: " epr panic ] [ drop ] if ] ,
;

: meta:create-cross ( name -- )
  x:create drop
  yes forth:mode!
  xlatest x:hide!
  [ xRET, xlatest x:show! no forth:mode! ]
;

: meta:create ( name -- )
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



( for const )
var: const-link

: const-link, ( xadr -- )
  # LIT v RET link
  xhere const-link x, -> const-link
;

: patch-const ( xadr -- )
  # LIT v RET link -> LIT v JMP xadr
  const-link [ ( adr link )
    0 [ STOP ] ;case
    dup x@ >r over swap x! r> GO
  ] while drop
  -1 -> const-link ( done )
;

: const-done const-link -1 = ;



( ===== Primitive Helper ===== )

: PRIMITIVES 1 [ drop ] ;

: PRIM: ( n closer q name: -- n+ )
  # : name <IMMED> LIT code LIT q JMP handler
  forth:read [ "Primitive name required" panic ] ;unless
  forth:create
  POSTPONE: <IMMED>
  >r over prim>code LIT, , r> LIT, , JMP,
  [ forth:mode [ drop x, ] [ nip >r ] if ] ,
  ' inc dip
;

: compile-only [ "compile only!" panic ] ;



( ===== Setup/Finish ===== )

var: m:image-name

: m:finish
  ( const )
  "doconst" x:find [ "doconst definition not found" panic ] ;unless
  xxt patch-const
  const-done [ "do patch-const" panic ] ;unless

  m:image-name [ "No image name" panic ] ;unless

  ( set entrypoint )
  CROSS-CORE ALSO
  "main" x:find [ "word 'main' required in [core]" panic ] ;unless xxt entrypoint!

  m:image-name save
;

: m:handle-num ( n -- )
  forth:mode [ xLIT, x, ] [ ( n -- n ) ] if
;

: m:parse-string ( -- )
  forth:mode [ xJMP, xhere 0 x, xhere swap ] [ xhere ] if
  forth:take drop ( skip first double quote )
  [ forth:take
    0  [ "Unclosed string" panic STOP ] ;case
    CHAR: " [ STOP ] ;case
    dup CHAR: \\ = [
      drop ' forth:take c:escaped
      [ "Escape sequence required" panic STOP ] ;unless
      bx, GO
    ] ;when
    bx, GO
  ] while
  0 bx, xhere:align!
  forth:mode [ xhere swap x! xLIT, x, ] when
;

[root] EDIT

: metacompile
  opt:read! [ "Image name required" panic ] ;unless -> m:image-name
  ( install )
  ' m:handle-num -> forth:handle-num
  ' m:parse-string -> forth:parse-string
  CROSS-CORE EDIT
  LEXI META CROSS-CORE CROSS-ROOT [root] ORDER
  ( start  ) "lib/core.f" include
  ( finish ) m:finish
;



( ###################### )
( ##### Meta Words ##### )
( ###################### )

( ----- aux word definitions ----- )
# meta words can't refer each other because of search order.
# ex. POSTPONE: '(tick) refers tick in core, not in META.
# so some shared routines must be defined here.

: aux-tick
  forth:read [ "Word name required" panic ] ;unless
  x:find [ epr " ?" panic ] ;unless
  xxt
  forth:mode [ xLIT, x, ] when
;

: aux-var
  forth:read [ "Var name required" panic ] ;unless
  30 s:check [ epr ": too long var name" panic ] ;unless
  dup >r
  dup x:create m:create
  xLIT, xhere swap x, xRET, r>
  dup "!" s:append!
  dup x:create m:create
  xLIT, x, x!, xRET,
;

: ;aux-compile ( name -- )
  forth:mode [ rdrop x:find [ epr " ?" panic ] ;unless xxt x, ] ;when
  drop
;

: aux-order ( 0 xlexi mlexi .. )
  LEXI ORDER
  xonly xprevious
  [ ?dup [ STOP ] ;unless ALSO xalso GO ] while
  META ALSO
;


( ----- COVER SHOW/HIDE ----- )

COVER

  var: public
  var: private
  var: xpublic
  var: xprivate

SHOW

  : aux-SHOW public  EDIT xpublic  xcurrent! ;
  : aux-HIDE private EDIT xprivate xcurrent! ;

  : aux-COVER ( -- priv pub xpriv xpub q )
    ( prev ) private public xprivate xpublic

    ( meta )
    lexi:new private!
    CURRENT  public!

    ( META -> private META )
    PREVIOUS private dup ALSO EDIT META ALSO

    ( cross )
    xlexi:new xprivate!
    xcurrent  xpublic!
    xprivate xalso xdefinitions

    ( close )
    [ PREVIOUS PREVIOUS META ALSO xprevious aux-SHOW
      xpublic! xprivate! public! private! ]
  ;

END



( ----- meta words order ----- )
# META < root < core
# overwrite
#   core: IF, :(colon), etc...
#   root: only, also, etc...

META EDIT LEXI [metacompiler] [forth] [core] [root] META ORDER



( ===== Meta Primitive word ===== )

PRIMITIVES

  [ HALT ] PRIM: HALT
  compile-only PRIM: LIT
  compile-only PRIM: RET

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

  compile-only PRIM: JMP
  compile-only PRIM: ZJMP

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

  compile-only PRIM: >r
  compile-only PRIM: r>
  compile-only PRIM: rdrop

  [ sp  ] PRIM: sp
  [ sp! ] PRIM: sp!
  [ rp  ] PRIM: rp
  [ rp! ] PRIM: rp!

END



( ===== Meta Lexicon Words ===== )

xlexi-core as: lexi-core
xlexi-root as: lexi-root

: [CORE] xlexi-core CROSS-CORE ;
: [ROOT] xlexi-root CROSS-ROOT ;

: [core] <IMMED> ( -- xcore mcore )
  forth:mode [ xLIT, lexi-core x, ] [ [CORE] ] if
;

: [root] <IMMED> ( -- xcore mcore )
  forth:mode [ xLIT, lexi-root x, ] [ [ROOT] ] if
;



( ===== Meta Syntax Words ===== )

: : <run-only>
  forth:read [ "Word name required" panic ] ;unless
  dup meta? [ meta:create-cross ] [ meta:create ] if
;

: ; <IMMED> ( q -- ) >r ;

: <IMMED> <IMMED> xlatest x:immed! ;

: as: ( n name: -- ) <run-only>
  forth:mode [ "Do not call as: in compile mode" panic ] ;when
  forth:read [ "Const name required" panic ] ;unless
  dup
  ( x-const ) x:create drop xLIT, over x, xJMP, const-link, xlatest x:immed!
  ( m-const )
  forth:create POSTPONE: <IMMED>
  LIT, , JMP,
  [ forth:mode [ xLIT, x, ] when ] ,
;

: patch-const ( xadr ) <run-only> patch-const ;


: [ <IMMED>
  forth:mode [ xJMP, xhere 0 x, ] when xhere ( &back &q | &q )
  forth:mode yes forth:mode! ( &back &q mode | &q mode )
  [ xRET,
    dup forth:mode!
    [ swap xhere swap x! xLIT, x, ] when
  ]
;

: ] <IMMED> ( q -- ) >r ;


: IF <IMMED> ( -- &back )
  xZJMP, xhere 0 x,
;

: ELSE <IMMED> ( &back -- &back2 )
  xJMP, xhere 0 x, swap ( &back2 &back )
  xhere swap x!
;

: THEN <IMMED> ( &back -- )
  xhere swap x!
;


: AGAIN <IMMED>
  xJMP, xlatest xxt x,
;


: END ( closer -- ) <IMMED> >r ;


: defer: ( name: -- ) <run-only>
  # JMP actual
  forth:read [ "Word name required" panic ] ;unless
  dup x:create m:create
  xJMP, 0 x,
;

: -> <IMMED> ( v &code -- )
  forth:read [ "Word name required" panic ] ;unless
  x:find [ epr "?" panic ] ;unless
  xxt
  # replace as `JMP|LIT v`
  cell + forth:mode [ xLIT, x, x!, ] [ x! ] if
;


: ' <IMMED> aux-tick ;


: POSTPONE: <IMMED>
  forth:mode [ "Do not use POSTPONE: in run mode" panic ] ;unless
  forth:read [ "Word name required" panic ] ;unless
  x:find [ epr " ?" panic ] ;unless
  xxt x,
;


: COMPILE: <IMMED>
  forth:mode [ "Do not use COMPILE: in run mode" panic ] ;unless
  aux-tick
  "," x:find [ "comma(,) is not defined yet in cross-env" panic ] ;unless
  xxt x,
;


: var> <run-only> aux-var ;

: var: <run-only> 0 aux-var ;


: CHAR: <IMMED>
  forth:read [ "A character required" panic ] ;unless
  dup b@ dup CHAR: \\ = [ drop inc
    [ [ inc ] [ b@ ] biq ] c:escaped
    [ "Escape sequence required" panic ] ;unless
  ] when nip
  forth:mode [ xLIT, x, ] when
;



: ( <IMMED> POSTPONE: ( ;
: # <IMMED> POSTPONE: # ;


COVER

  xhere 0 x, as: link

SHOW

  link as: init:link

  : >init <run-only>
    xhere link x@ x, link x!
    x,
  ;

  : init:run <IMMED>
    "init:run" x:find [ drop "Define init:run" panic ] ;unless
    xxt x,
  ;

END


( ----- lexicon ----- )

: lexicon: <run-only>
  # meta:  ( -- xlexi mlexi )
  # cross: ( -- xlexi )
  forth:read [ "lexicon name required" panic ] ;unless
  >r i lexi:create i xlexi:create ( mlexi xlexi )
  ( cross ) i x:create drop xLIT, dup x, xJMP, const-link, xlatest x:immed!
  ( meta )
  r> forth:create POSTPONE: <IMMED>
  ( mlexi xlexi ) LIT, , LIT, , JMP, [ forth:mode [ drop xLIT, x, ] when ] ,
;

: PREVIOUS <IMMED>
  "PREVIOUS" ;aux-compile
  PREVIOUS PREVIOUS META ALSO
  xprevious
;

: LEXI <IMMED>
  "LEXI" ;aux-compile 0
;

: REFER <IMMED>
  "REFER" ;aux-compile [CORE] [ROOT] aux-order
;

: ORDER <IMMED>
  "ORDER" ;aux-compile aux-order
;

: EDIT <IMMED>
  "EDIT" ;aux-compile EDIT xcurrent!
;

: ALSO <IMMED>
  "ALSO" ;aux-compile
  PREVIOUS ALSO META ALSO
  xalso
;

: TEMPORARY <IMMED> ( -- lexis current xlexis xcurrent q )
  "TEMPORARY" ;aux-compile
  CONTEXT CURRENT xcontext xcurrent [ xedit xorder EDIT ORDER ]
;

: COVER <IMMED> "COVER" ;aux-compile aux-COVER ;
: SHOW  <IMMED> "SHOW"  ;aux-compile aux-SHOW ;
: HIDE  <IMMED> "HIDE"  ;aux-compile aux-HIDE ;

hashd-len as: mhashd-len


( ----- debug ----- )

: ?H <IMMED> "HERE" prn ;

: ?STACK <IMMED> ?stack ;

: ?WORDS <IMMED> cr ?words ;


( ####################### )
( ## Start Metacompile ## )
( ####################### )

metacompile
