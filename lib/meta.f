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

only definitions [core] also
  lexicon: META
  lexicon: CROSS-ROOT
  lexicon: CROSS-CORE

only [core] also definitions [file] also [forth] also

lexicon: [metacompiler]
[metacompiler] also definitions


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
0x0C as: adr_lexicons   ( lexicon order )
0x10 as: adr_lexisp ( lexicon stack pointer )
0x14 as: adr_current ( defining lexicon )
0x18 as: adr_begin


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

: xallot ( n -- addr ) xhere tuck + xhere! ;



( ----- initialize ----- )

adr_begin xhere!


( ----- string ----- )

: x:sput ( s -- )
  dup s:len inc >r xhere x>t s:copy r> xhere + xhere! xhere:align!
;



( ===== Save Image ===== )

: entrypoint! ( xadr -- ) adr_start x! ;

: image_size xhere x>t there - ;


COVER

  var: id

SHOW

  : save ( fname -- )
    " wb" file:open! id!
    there image_size id file:write!
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
# | next
# | latest
# | name

: xlexis  adr_lexicons x@ ;
: xlexis! adr_lexicons x! ;
: xlexisp  adr_lexisp x@ ;
: xlexisp! adr_lexisp x! ;
: xcurrent  adr_current x@ ;
: xcurrent! adr_current x! ;

16 cells as: xlexi:size
xlexi:size xallot xlexis!
xlexis xlexisp!

: xlexi:new ( -- adr )
    xhere:align! xhere 0 x, 0 x,
;

: xlexi:latest  ( lexi -- word ) x@ ;
: xlexi:latest! ( word lexi -- ) x! ;
: xlexi:name    ( lexi -- name ) cell + x@ ;
: xlexi:name!   ( name lexi -- ) cell + x! ;

: xlexi:create ( name -- adr )
     xhere swap x:sput ( name )
     xlexi:new tuck xlexi:name!
;

: xalso ( lexi -- ) xlexisp x! xlexisp cell + xlexisp! ;
: xprevious ( -- ) xlexisp cell - xlexisp! ;
: xdefinitions ( -- ) xlexisp cell - x@ xcurrent! ;

" [core]" xlexi:create as: xlexi_core
" [root]" xlexi:create as: xlexi_root

xlexi_root xalso
xlexi_core xalso
xlexi_core xcurrent!

: xonly ( -- ) xlexis xlexisp! xlexi_root xalso ;

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


: xlatest  xcurrent xlexi:latest  ;
: xlatest! xcurrent xlexi:latest! ;

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

: x:find_in ( name lexi -- xword yes | name no )
    xlexi:latest [
        0 [ no STOP ] ;case
        2dup xname x>t s= [ nip yes STOP ] ;when
        xnext GO
    ] while
;

: x:find ( name -- xword yes | name no )
  xlexisp cell - swap [ ( sp name )
      over xlexis < [ nip no STOP ] ;when
      over x@ x:find_in [ nip yes STOP ] [ [ cell - ] dip GO ] if
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


: meta? ( s -- ? ) META forth:find_in nip ;

: <run_only> <IMMED>
  POSTPONE: <IMMED>
  LIT, forth:latest forth:name 2 + ,
  [ forth:mode [ " Do not compile: " epr panic ] [ drop ] if ] ,
;

: meta:create_cross ( name -- )
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
  forth:create
  POSTPONE: <IMMED>
  >r over prim>code LIT, , r> LIT, , JMP,
  [ forth:mode [ drop x, ] [ nip >r ] if ] ,
  ' inc dip
;

: compile_only [ panic" compile only!" ] ;



( ===== Setup/Finish ===== )

var: m:image_name

: m:finish
  ( const )
    " doconst" x:find [ panic" doconst definition not found" ] ;unless
    xxt patch_const
    const_done [ panic" do patch_const" ] ;unless

  m:image_name [ panic" No image name" ] ;unless

  ( set entrypoint )
  CROSS-CORE also
  " main" x:find [ panic" word 'main' required in [core]" ] ;unless xxt entrypoint!

  m:image_name save
;

: m:handle_num ( n -- )
  forth:mode [ xLIT, x, ] [ ( n -- n ) ] if
;

[root] current !

: metacompile
  opt:read! [ panic" Image name required" ] ;unless -> m:image_name
  ( install )
  ' m:handle_num -> forth:handle_num
  only
    CROSS-ROOT also
    CROSS-CORE also definitions
    META  also ( use meta words first )
  ( start  ) " lib/core.f" include
  ( finish ) m:finish
;



( ###################### )
( ##### Meta Words ##### )
( ###################### )

( ----- aux word definitions ----- )
# meta words can't refer each other because of search order.
# ex. POSTPONE: '(tick) refers tick in core, not in META.
# so some shared routines must be defined here.

: aux_tick
    forth:read [ panic" Word name required" ] ;unless
    x:find [ epr "  ?" panic ] ;unless
    xxt
    forth:mode [ xLIT, x, ] when
;

: aux_var
    forth:read [ panic" Var name required" ] ;unless
    30 s:check [ epr panic" : too long var name" ] ;unless
    dup >r
    dup x:create m:create
    xLIT, xhere swap x, xRET, r>
    dup " !" s:append!
    dup x:create m:create
    xLIT, x, x!, xRET,
;

: ;aux_compile ( name -- )
    forth:mode [ rdrop x:find [ epr panic"  ?" ] ;unless xxt x, ] ;when
    drop
;

( ----- COVER SHOW/HIDE ----- )

COVER

    var: public
    var: private
    var: xpublic
    var: xprivate

SHOW

    : aux_SHOW public  current ! xpublic  xcurrent! ;
    : aux_HIDE private current ! xprivate xcurrent! ;

    : aux_COVER ( -- priv pub xpriv xpub q )
        ( prev ) private public xprivate xpublic

        ( meta )
            lexi:new  private!
            current @ public!
            ( META -> private META )
            previous private also definitions META also
        ( cross )
            xlexi:new xprivate!
            xcurrent  xpublic!
            xprivate xalso xdefinitions
        ( close )
            [ previous previous META also xprevious aux_SHOW
              xpublic! xprivate! public! private! ]
    ;

END



( ----- meta words order ----- )
# META < root < core
# overwrite
#   core: IF, :(colon), etc...
#   root: only, also, etc...

only
  META also definitions
  [root] also
  [core] also
  [forth] also
  [metacompiler] also



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



( ===== Meta Lexicon Words ===== )

xlexi_core as: lexi_core
xlexi_root as: lexi_root

: <CORE> xlexi_core CROSS-CORE ;
: <ROOT> xlexi_root CROSS-ROOT ;



( ===== Meta Syntax Words ===== )

: : <run_only>
  forth:read [ panic" Word name required" ] ;unless
  dup meta? [ meta:create_cross ] [ meta:create ] if
;

: ; <IMMED> ( q -- ) >r ;

: <IMMED> <IMMED> xlatest x:immed! ;

: as: ( n name: -- ) <run_only>
  forth:mode [ panic" Do not call as: in compile mode" ] ;when
  forth:read [ panic" Const name required" ] ;unless
  dup
  ( x-const ) x:create drop xLIT, over x, xJMP, const_link, xlatest x:immed!
  ( m-const )
  forth:create POSTPONE: <IMMED>
  LIT, , JMP,
  [ forth:mode [ xLIT, x, ] when ] ,
;

: patch_const ( xadr ) <run_only> patch_const ;


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


: PRIVATE ( -- xstart mstart closer ) <run_only>
  xlatest forth:latest [ forth:latest forth:hide_range xlatest x:hide_range ]
;

: PUBLIC ( xstart mstart closer -- xstart xend mstart mend closer ) <run_only>
  drop xlatest swap forth:latest [ forth:hide_range x:hide_range ]
;

: END ( closer -- ) <IMMED> >r ;


: defer: ( name: -- ) <run_only>
  # JMP actual
  forth:read [ panic" Word name required" ] ;unless
  dup x:create m:create
  xJMP, 0 x,
;

: -> <IMMED> ( v &code -- )
  forth:read [ panic" Word name required" ] ;unless
  x:find [ epr " ?" panic ] ;unless
  xxt
  # replace as `JMP|LIT v`
  cell + forth:mode [ xLIT, x, x!, ] [ x! ] if
;


: ' <IMMED> aux_tick ;


: POSTPONE: <IMMED>
  forth:mode [ panic" Do not use POSTPONE: in run mode" ] ;unless
  forth:read [ panic" Word name required" ] ;unless
  x:find [ epr panic"  ?" ] ;unless
  xxt x,
;


: COMPILE: <IMMED>
  forth:mode [ panic" Do not use COMPILE: in run mode" ] ;unless
  aux_tick
  " ," x:find [ panic" comma(,) is not defined yet in cross-env" ] ;unless
  xxt x,
;


: var> <run_only> aux_var ;

: var: <run_only> 0 aux_var ;


: CHAR: <IMMED>
  forth:read [ panic" A character required" ] ;unless
  dup b@ dup CHAR: \\ = [ drop inc
    [ [ inc ] [ b@ ] biq ] c:escaped
    [ panic" Escape sequence required" ] ;unless
  ] when nip
  forth:mode [ xLIT, x, ] when
;


: " <IMMED>
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

: ( <IMMED> POSTPONE: ( ;
: # <IMMED> POSTPONE: # ;


COVER

  xhere 0 x, as: link

SHOW

  link as: init:link

  : >init <run_only>
    xhere link x@ x, link x!
    x,
  ;

  : init:run <IMMED>
    " init:run" x:find [ drop panic" Define init:run" ] ;unless
    xxt x,
  ;

END


( ----- lexicon ----- )

: lexicon: <run_only>
    # meta:  ( -- xlexi mlexi )
    # cross: ( -- xlexi )
    forth:read [ panic" lexicon name required" ] ;unless
    >r i lexi:create i xlexi:create ( mlexi xlexi )
    ( cross ) i x:create drop xLIT, dup x, xJMP, const_link, xlatest x:immed!
    ( meta )
    r> forth:create POSTPONE: <IMMED>
    ( mlexi xlexi ) LIT, , LIT, , JMP, [ forth:mode [ drop xLIT, x, ] when ] ,
;

: definitions ( -- ) <IMMED>
    " definitions" ;aux_compile
    previous definitions META also
    xdefinitions
;

: also ( xlexi mlexi -- ) <IMMED>
    " also" ;aux_compile
    previous also META also
    xalso
;

: only ( -- ) <IMMED>
    # meta:  root CROSS-ROOT META
    # cross: root
    " only" ;aux_compile
    only CROSS-ROOT also META also
    xonly
;

: previous <IMMED>
    " previous" ;aux_compile
    previous previous META also
    xprevious
;

: COVER <IMMED> " COVER" ;aux_compile aux_COVER ;
: SHOW  <IMMED> " SHOW"  ;aux_compile aux_SHOW ;
: HIDE  <IMMED> " HIDE"  ;aux_compile aux_HIDE ;



( ----- debug ----- )

: ?H <IMMED> " HERE" prn ;

: ?STACK <IMMED> ?stack ;

: ?WORDS <IMMED> cr ?words ;


( ####################### )
( ## Start Metacompile ## )
( ####################### )

metacompile
