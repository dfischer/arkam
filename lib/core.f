# ======================
#      Forth Core
# ======================
#
# lib/meta.f compiles this to Forth base image file.
#
# === Run mode
# You can
#   - define and use constant words defined by `as:`
#   - define variables with `var:` and `var>`
#   - run meta words defined by `M:` in meta.f
#   - put literals (ex. -123, 0xFF)
# You can't
#   - run cross-words defined here
#
# === Compile mode
# You can
#   - compile cross-words defined by `:`
#   - compile constant words defined by `as:`
#   - compile variables defined by `var:` and `var>`
#   - run meta words defined in meta.f
# You can't
#   - run immediate cross-words defined here

LEXI REFER [core] EDIT



# ----- Memory Layout -----
# 0x04 &start
# 0x08 here
# 0x0C lexicons -> [forth]
# 0x10 lexisp   -> [forth]
# 0x14 current  -> [core]
# 0x18 begin


: here    0x08 @ ;
: here!   0x08 ! ;



( ===== Boolean ===== )

-1 as: ok
 0 as: ng

ok as: yes
ng as: no

ok as: GO
ng as: STOP


: not IF no ELSE yes THEN ;



( ===== Stack ===== )

: nip   swap drop ; # a b -- b
: 2dup  over over ; # a b -- a b a b
: 2drop drop drop ; # x x --
: 3drop drop drop drop ; # x x x --

: tuck ( a b -- b a b ) swap over ;
: ?dup ( a -- a a | 0 ) dup IF dup THEN ;

: pullup   ( a b c -- b c a ) >r swap r> swap ;
: pushdown ( b c a -- a b c ) swap >r swap r> ;

( ===== Compare ===== )

: <=  > inv ; # a b -- ?
: >=  < inv ; # a b -- ?


: max  over over < IF swap THEN drop ; # a b -- a|b
: min  over over > IF swap THEN drop ; # a b -- a|b



( ===== Arithmetics ===== )

: /   ( a b -- a/b ) /mod drop ;
: mod ( a b -- a%b ) /mod swap drop ;

: neg ( n -- n ) -1 * ;

: abs dup 0 < IF neg THEN ;

: inc 1 + ;
: dec 1 - ;

: clamp ( n min max -- min<=n<max )
    >r 2dup < IF rdrop nip RET THEN # -- min
    drop r> 2dup < IF drop RET THEN # -- n
    nip dec # -- max-1
;


: within? ( n min max -- min<=n<max? )
    >r over > IF rdrop drop no RET THEN
    r> <
;



( ===== Bitwise ===== )

: <<  ( n -- n )     lsft ;
: >>  ( n -- n ) neg lsft ;
: >>> ( n -- n ) neg asft ;



( ===== Heap ===== )

4 as: cell
: cells ( n -- n ) cell * ;
: align ( n -- n ) 3 + 3 inv and ;

: here:align! here align here! ;
: ,  here  ! here cell + here! ;
: b, here b! here inc    here! ;

: allot here tuck + here! ; # n -- adr



( ===== Quotation 1 ===== )

: call ( q -- ) >r ;

: if ( ? q1 q2 -- ) >r swap IF rdrop >r ELSE drop THEN ;
    # example:
    #   yes [ "hello" ] [ "world" ] if pr
    # => hello

: when   ( ? q -- ) swap IF >r ELSE drop THEN ;
: unless ( ? q -- ) swap IF drop ELSE >r THEN ;


# ;when / ;unless
# call q and exit from caller if ? is true
: ;when   ( ? q -- ... ) swap IF rdrop >r RET ELSE drop         THEN ;
: ;unless ( ? q -- ... ) swap IF drop         ELSE rdrop >r RET THEN ;


: ;case ( a b q -- ... | a )
    # if a=b call q and escape from caller
    # or ramain a
    >r over = IF drop r> rdrop >r RET THEN rdrop
;

: ;eq ( a b -- yes | a )
    # same as [ yes ] ;case
    over = IF drop rdrop yes THEN
;



( ===== Stack 2 ===== )

: pick ( n -- v ) 2 + cells sp + @ ;
    # example:
    #   1 2 3 0 pick => 1 2 3 3
    #   1 2 3 2 pick => 1 2 3 1
    # stack:
    #   sp: |
    #       | n
    #       | ...
    # target address: sp + (n+2)*cells


: rpick ( n -- v ) 2 + cells rp + @ ;
    # rstack:
    #   rp: |
    #       | caller
    #   n=0 | ...
    #   n=1 | ...
    # target address: rp + (n+2)*cells


: i ( -- v ) 2 cells rp + @ ;
: j ( -- v ) 3 cells rp + @ ;



( ===== Memory ===== )

: inc! ( adr -- ) dup @ 1 + swap ! ;
: dec! ( adr -- ) dup @ 1 - swap ! ;

: +! ( v adr -- ) swap over @ + swap ! ;
: -! ( v adr -- ) swap over @ - swap ! ;

: update! ( adr q -- )
    # q: v -- v
    over >r swap @ swap call r> !
;

: on  or      ; # n -- n
: off inv and ; # n -- n

: on!  swap [ swap on  ] update! ; # adr flag --
: off! swap [ swap off ] update! ; # adr flag --



( ===== Combinator ===== )

: dip ( a q -- ... ) swap >r call r> ;
    # escape a, call q, then restore a
    # example:
    #   1 3 [ inc ] dip  => 2 3


: sip ( a q -- ... a ) over >r call r> ;
    # copy & restore a
    # eample:
    #   1 [ inc ] => 2 1


: biq ( a q1 q2 -- aq1 aq2 ) >r over >r call r> ; ( return to quotation )
    # biq - bi quotations application


: bia ( a b q -- aq bq ) swap over >r >r call r> ; ( return to quotation )
    # bia - bi arguments application


: bi* ( a b q1 q2 -- aq1 bq2 ) >r swap >r call r> ; ( return to quotation )


: bibi ( a b q1 q2 -- abq1 abq2 )
    >r >r 2dup ( a b a b | q2 q1 )
    r> swap >r ( a b a q1 | q2 b )
    swap >r    ( a b q1 | q2 b a )
    call r> r> ; ( return to quotation )


: triq ( a q1 q2 q3 -- aq1 aq2 aq3 )
    >r >r over r> swap >r ( a q1 q2 | q3 a )
    biq r> ; ( return to quotation )
    # triq - tri quotations application


: tria ( a b c q -- aq bq cq )
    swap over >r >r ( a b q | q c )
    bia r> ; ( return to quotation )
    # tria - tri arguments application


: tri* ( a b c q1 q2 q3 -- aq1 bq2 cq3 )
    >r >r swap r> swap >r ( a b q1 q2 | q3 c )
    bi* r> ; ( return to quotation )



( ===== Iterator ===== )

COVER
    : loop ( q n ) dup 1 < IF 2drop RET THEN
        1 - over swap >r >r call r> r> AGAIN
    ;
SHOW
    : times ( n q -- ) swap loop ;
END


COVER
    : loop ( q n i )
        2dup <= IF 3drop RET THEN
        swap over 1 +     # q i n i+1
        >r >r swap dup >r # i q | i+1 n q
        call r> r> r> AGAIN
    ;
SHOW
  : for ( n q -- ) swap 0 loop ;
END


COVER
    : loop ( q n )
        dup 1 < IF 2drop RET THEN
        dec 2dup >r >r swap call r> r> AGAIN
    ;
SHOW
    : for- ( n q -- ) swap loop ;
END


: while ( q -- )
    # loop while q put yes to TOS
    dup >r call IF r> AGAIN THEN rdrop
;


( ===== System ===== )

LEXI REFER [core] EDIT
lexicon: [sys]
[sys] ALSO [sys] EDIT

COVER
    : query 0 io ;
SHOW
    : sys:size 0      query ;
    : sys:ds-size 2   query ;
    : sys:ds      3   query ;
    : sys:rs-size 4   query ;
    : sys:rs      5   query ;
    : sys:cell-size 6 query ;
    : sys:max-int 7   query ;
    : sys:min-int 8   query ;
    : sys:dstack! 9   query ; # sp adr cells --
    : sys:rstack! 10  query ; # rp adr cells --
    ( calculated )
    : sys:ds-base sys:ds-size cells sys:ds + ;
    : sys:rs-base sys:rs-size cells sys:rs + ;
    : sys:depth sp cell + sys:ds-base swap - cell / ; # order matters
    : sys:ds0! sys:ds-base cell - sp! ;
END


LEXI REFER [root] EDIT
: bye 0 HALT ;
: die 1 HALT ;


( ===== Defered ===== )
# defined here for stdio
LEXI REFER [core] EDIT
: defered ( xt -- ) cell + @ ;



( ===== Stdio ===== )

LEXI REFER [core] EDIT
lexicon: [stdio]
[stdio] ALSO

[stdio] EDIT
# port 1:stdout 2:stderr
: stdio:ready? -1 1 io ; # -- ?
: (putc)          0 1 io ; # c --
: (getc)          1 1 io ; # -- c
: (eputc)         2 1 io ; # c --


[core] EDIT
defer: putc  ' (putc) -> putc
defer: getc  ' (getc) -> getc


[core] EDIT
: cr    10 putc ;
: space 32 putc ;

: pr ( s -- )
    dup b@ dup 0 = [ 2drop ] ;when
    putc 1 + AGAIN
;

: prn ( s -- ) pr cr ;


[stdio] EDIT
: call/putc ( &putc q -- )
        # call-with-putc
        # call q with &putc then restore previous port
        ' putc defered >r
        swap -> putc call
        r> -> putc
;


[core] EDIT
: >stdout ( q -- ) ' (putc)  swap call/putc ;
: >stderr ( q -- ) ' (eputc) swap call/putc ;


[core] EDIT
: epr  ( s -- ) [ pr  ] >stderr ;
: eprn ( s -- ) [ prn ] >stderr ;

: getline ( buf len -- success? )
    swap ( len buf )
    [ over 1 < [ ng STOP ] ;when
        getc ( len buf c )
        0  [ 0 swap b! drop ok STOP ] ;case
        10 [ 0 swap b! drop ok STOP ] ;case
        over b! ' dec ' inc bi* GO
    ] while
;


[stdio] EDIT
: (panic) eprn die ;

[core] EDIT
defer: panic
' (panic) -> panic



( ===== Debug print ===== )
LEXI REFER [core] EDIT

: >hex ( n -- c ) dup 10 < IF 48 ELSE 55 THEN + ;

: ?h "HERE" prn ;

COVER

    11 as: max ( i32: max "-2147483648" )
    var: buf
    var: n
    var: posi
    var: base
    var: q
    var: r
    var: i

    : init buf max + i! ;
    : check buf i > IF "too big num" panic THEN ;
    : put i 1 - dup i! b! ; # c --
    : put-sign posi IF RET THEN 45 put ;
    : check-sign n 0 < IF n neg n! no ELSE yes THEN posi! ;
    : read n base /mod r! q!
        r >hex put
        q 0 = IF RET THEN q n! AGAIN
    ;
    : check-min ( minimum number )
        n 0 = IF "0" rdrop RET THEN
        n dup neg != IF RET THEN ( 0x80000000 * -1 = 0x80000000 )
        10 base = IF "-2147483648" rdrop RET THEN
        16 base = IF "-80000000"   rdrop RET THEN
        "?: invalid base" panic
    ;

    [ buf IF RET THEN max 1 + allot buf! ] >init

SHOW

    : n>s ( n base -- buf )
        base! n! check-min check-sign init read put-sign i
    ;

    : n>dec ( n -- buf ) 10 n>s ;
    : n>hex ( n -- buf ) 16 n>s ;

    : ?    dup n>dec pr space ;
    : ?hex dup n>hex pr space ;

END


: .. ? drop ;
: . .. cr ;

: ..hex "0x" pr dup 0x10 < [ "0" pr ] when ?hex drop ;
: .hex ..hex cr ;


[sys] ALSO
: ?stack ( -- )
    [ sp cell + ( adr )
        sys:depth dec [ ( adr i )
            cells over + @ ..
        ] for- drop
        cr
    ] >stderr
;
PREVIOUS

: ff ( n -- ) 0xFF and 16 /mod swap >hex putc >hex putc ;


COVER
    16 as: bpl ( bytes per line )
    var: adr
    var: len
    var: base
    var: lines
    var: rest

    : ascii ( n -- )
        dup 32  < [ drop CHAR: . putc ] ;when
        dup 126 > [ drop CHAR: . putc ] ;when
        putc
    ;

    : where
        base 24 >> ff
        base 16 >> ff
        base  8 >> ff
        base       ff
    ;

    : bytes ( n -- )
        [ base + b@ ff space ] for
    ;

    : text ( n -- )
        [ base + b@ ascii ] for
    ;

SHOW
    : dump ( adr len ) len! adr!
        len bpl / lines!
        lines [ bpl * adr + base!
            where "| " pr
            bpl bytes
            bpl text
            cr
        ] for
        len bpl mod 0 [ ( noop ) ] ;case rest!
        lines bpl * adr + base!
        where "| " pr
        rest bytes
        bpl rest - [ "   " pr ] times
        rest text
        cr
    ;
END



( ===== Memory and String ===== )

: memcopy ( src dst len -- )
    dup 1 < IF 3drop RET THEN
    1 - >r
    over b@ over b!
    1 + swap 1 + swap
    r> AGAIN
;

: memclear ( adr len -- ) [ 0 over b! inc ] times drop ;

: s:end ( s -- s+ ) dup b@ IF inc AGAIN THEN ;

: s:len ( s -- n ) dup s:end swap - ;

: s:hash ( s -- n )
    # DJB2 algorithm
    5381 [
        over b@ ( s hash c )
        0 [ nip STOP ] ;case
        over 5 << + + [ inc ] dip GO
    ] while
;

: s= ( s1 s2 -- ? )
    [ 2dup [ b@ ] bia over != # s1 s2 c diff?
        ( diff ) [ 3drop no STOP ] ;when
        ( end  ) 0 [ 2drop yes STOP ] ;case drop
        ( next ) ' inc bia GO
    ] while
;


: c:digit? ( c -- ? ) dup CHAR: 0 < [ drop no ] [ CHAR: 9 <= ] if ;
: c:upper? ( c -- ? ) dup CHAR: A < [ drop no ] [ CHAR: Z <= ] if ;
: c:lower? ( c -- ? ) dup CHAR: a < [ drop no ] [ CHAR: z <= ] if ;

: c>dec ( c -- n yes | no )
    dup c:digit? [ CHAR: 0 - yes ] [ drop no ] if
;

: c>hex ( c -- n yes | no )
    dup CHAR: 0 <  [ drop no  ] ;when  # < 0
    dup CHAR: 9 <= [ 48 - yes ] ;when  # 0-9
    dup CHAR: A <  [ drop no  ] ;when  # 9 < c < A
    dup CHAR: G <  [ 55 - yes ] ;when  # A-F
    dup CHAR: a <  [ drop no  ] ;when  # A < c < a
    CHAR: a - dup 6 > [ drop no ] [ 10 + yes ] if
;



COVER
    var: base
SHOW
    : s>n ( s base -- n yes | no )
        base!
        dup b@ CHAR: - = IF inc -1 ELSE 1 THEN swap ( sign s )
        dup b@ [ 2drop no ] ;unless ( null string )
        0 swap ( sign acc s )
        [ dup b@
            ( done      ) 0 [ drop yes STOP ] ;case
            ( NaN       ) c>hex [ drop no STOP ] ;unless
            ( over base ) dup base >= [ 2drop no STOP ] ;when
            ( ok        ) pullup base * + swap inc GO
        ] while ( sign acc dec? )
        IF * yes ELSE 2drop no THEN
    ;
    : s>dec 10 s>n ;  # s -- n yes | no
    : s>hex 16 s>n ;  # s -- n yes | no
END



: c:escaped ( qtake -- c ok | ng )
    dup >r call r> swap
    ( no following sequence ) 0 [ drop ng ] ;case
    ( \b bs      ) CHAR: b [ drop 8  ok ] ;case
    ( \t htab    ) CHAR: t [ drop 9  ok ] ;case
    ( \n newline ) CHAR: n [ drop 10 ok ] ;case
    ( \r cr      ) CHAR: r [ drop 13 ok ] ;case
    ( \" dquote  ) CHAR: " [ drop 34 ok ] ;case
    ( \0 null    ) CHAR: 0 [ drop 0  ok ] ;case
    ( as-is      ) nip ok
;



: s:each ( s q -- ) # q: ( c -- )
    swap
    [ dup b@ ( q s c )
        0 [ 2drop STOP ] ;case
        swap inc >r swap dup >r call r> r> GO
    ] while
;

: s:put ( s -- adr )
    here >r [ b, ] s:each 0 b, r>
;

: s:copy ( src dst )
    swap [ over b! inc ] s:each
    0 swap b!
;


: s:check ( str max -- str ok? )
    # check length
    # max includes null termination
    over s:len 1 + >=
;


: s:append! ( dst what -- )
    ( no check )
    ' s:end dip ( dst+ what )
    [ 2dup b@ swap over swap b!
        [ ' inc bia GO ] [ 2drop STOP ] if
    ] while
;

: s:append ( dst what max -- ? )
    # max includes null termination
    ( check )
    >r 2dup ' s:len bia + inc r>
    > [ 2drop ng ] ;when
    s:append! ok
;


: s:start? ( src what -- ? )
    # src starts with what?
    [ 2dup [ b@ ] bia
        0      [ 3drop yes STOP ] ;case
        swap 0 [ 3drop no  STOP ] ;case
        =      [ ' inc bia GO    ] ;when
        2drop no STOP
    ] while
;


COVER # ----- s:each-line! -----

    # destructive!
    # Every newline in s will be replaced by 0

    : split ( src -- line src+ yes | no )
        dup b@ [ drop no ] ;unless
        dup ( line src )
        [ dup b@
            0  [ yes STOP ] ;case
            10 [ [ inc ] [ 0 swap b! ] biq yes STOP ] ;case
            drop inc GO
        ] while
    ;

SHOW

    : s:each-line! ( s q -- )
        [ >r split not IF rdrop STOP RET THEN
            i swap >r call r> r>  GO
        ] while
    ;

END



( ===== Random ===== )

: rand       0 2 io ;
: rand:seed! 1 2 io ;
: rand:init  2 2 io ;

: shuffle ( adr len -- )
    tuck [ ( len adr i -- )
        cells >r over rand cells over + over r> + ( len adr src dst )
        [ dup @ ] bia >r ! r> swap !
    ] for 2drop
;



( ===== File ===== )

LEXI REFER [core] EDIT
lexicon: [file]
LEXI [file] REFER [file] EDIT


COVER
    : query    8 io ;
SHOW
    : file:ready?  -1  query ; # -- ?
    : file:open     0  query ; # path mode -- id ok | ng
    : file:close    1  query ; # id -- ?
    : file:read     2  query ; # buf len id -- ?
    : file:write    3  query ; # buf len id -- ?
    : file:seek     4  query ; # id offset origin -- ?
    : file:exists?  5  query ; # path -- ?
    : file:getc     6  query ; # id -- c | 0
    : file:putc     7  query ; # c id --
    : file:peek     8  query ; # id -- c | 0
    : file:fullpath 9  query ; # path buf max -- ?
    : file:size     10 query ; # id -- n
    ( --- defensive --- )
    : file:open!  file:open [ "Can't open " epr eprn die ] unless ; # path mode -- id
    : file:close! file:close drop ; # id --
    : file:read!  file:read  IF RET THEN "Can't read" panic ;
    : file:write! file:write IF RET THEN "Can't write" panic ;
END



( ===== CLI ===== )

LEXI REFER [core] EDIT

: cli:query 12 io ;
: cli:argc    0 cli:query ; # -- n
: cli:get-arg 1 cli:query ; # buf i len -- ?

: cli:get-arg! ( buf i len -- )
    cli:get-arg IF RET THEN "Can't get arg!" panic
;



( ===== Forth ===== )

LEXI REFER [core] EDIT

lexicon: [forth]


var: forth:mode
: forth:mode! forth:mode! ;


[forth] ALSO [forth] EDIT

1 as: forth:compile-mode
0 as: forth:run-mode

0x01 as: flag-immed
0x02 as: flag-hidden

0x0C as: lexicons
0x10 as: lexisp
0x14 as: current

mhashd-len as: hashd-len

: lexi:new ( -- adr )
    here:align! here
    ( latest ) 0 ,
    ( name   ) 0 ,
    ( hashd  ) hashd-len [ 0 , ] times
;

: lexi:latest  @ ;
: lexi:latest! ! ;
: lexi:name  cell + @ ;
: lexi:name! cell + ! ;
: lexi:hashd 2 cells + ;

: lexi:name lexi:name dup [ drop "???" ] unless ;  # for anonymous lexicon

: lexi:create ( name -- adr )
    s:put lexi:new tuck lexi:name!
;



LEXI [forth] REFER [root] EDIT

lexi-core as: [core]
lexi-root as: [root]
: PREVIOUS ( -- ) lexisp @ cell - lexisp ! ;
: CURRENT ( -- lexi ) current @ ;
: EDIT    ( lexi -- ) current ! ;
: ALSO    ( lexi -- ) lexisp @ ! lexisp @ cell + lexisp ! ;



LEXI [forth] REFER [core] EDIT

: forth:latest  CURRENT lexi:latest  ;
: forth:latest! CURRENT lexi:latest! ;


# Dictionary
# | next:30 | hidden:1 | immed:1  tagged 32bit pointer
# | flags
# | &name
# | &code
# | code...


LEXI [forth] REFER [forth] EDIT

: forth:next  @ ; # &entry -- &entry
: forth:next! ! ; # &next &entry --

: forth:flags  cell + @ ;
: forth:flags! cell + ! ;
: forth:flag-on!  ( &entry flag ) swap cell + dup >r @ swap on  r> ! ;
: forth:flag-off! ( &entry flag ) swap cell + dup >r @ swap off r> ! ;

: forth:hide! flag-hidden forth:flag-on!  ; # &entry --
: forth:show! flag-hidden forth:flag-off! ; # &entry --
: forth:hidden? forth:flags flag-hidden and ; # &entry -- ?

: forth:immed!     flag-immed forth:flag-on!  ; # &entry --
: forth:non-immed! flag-immed forth:flag-off! ; # &entry --
: forth:immed? forth:flags flag-immed and ; # &entry -- ?


LEXI [forth] REFER [core] EDIT

: forth:name  2 cells + @    ; # &entry -- &name
: forth:name! 2 cells + !    ; # &name -- &entry

: forth:code  3 cells + @ ; # &entry -- &code
: forth:code! 3 cells + ! ; # &code &entry --


LEXI [forth] REFER [forth] EDIT

: hashd-link ( lexi s -- link )
    s:hash abs hashd-len mod cells ( offset )
    swap lexi:hashd +
;

: forth:register ( lexi word -- )
    tuck forth:name hashd-link ( word link )
    2dup @ swap forth:next! !
;


LEXI [forth] REFER [core] EDIT

: forth:create ( name -- )
    here:align! s:put here:align! ( &name )
    ( latest ) here forth:latest!
    ( next   ) 0 ,
    ( flags  ) 0 ,
    ( &name  ) ,
    ( &code  ) here cell + ,
    CURRENT forth:latest forth:register
;


LEXI [forth] REFER [forth] EDIT

: forth:remove ( word lexi -- )
    over forth:name hashd-link ( target link )
    dup @ [ ( target link word )
        0 [ drop forth:name epr space "?" panic ] ;case
        swap >r 2dup = r> swap ( target word link ? )
        [ [ forth:next ] dip ! drop STOP ] ;when
        drop dup forth:next GO
    ] while
;

: forth:find-in ( name lexi -- name no | word yes )
    over hashd-link @ [ ( name latest )
        ( notfound ) 0 [ no STOP ] ;case
        ( hidden   ) dup forth:hidden? [ forth:next GO ] ;when
        ( found    ) 2dup forth:name s= [ nip yes STOP ] ;when
        ( next     ) forth:next GO
    ] while
;

: forth:(find) ( name -- name no | word yes )
    lexisp @ cell - swap [ ( sp name )
        over lexicons @ < [ nip no STOP ] ;when
        over @ forth:find-in [ nip yes STOP ] [ [ cell - ] dip GO ] if
    ] while
;


LEXI [forth] REFER [core] EDIT

defer: forth:find
' forth:(find) -> forth:find

: forth:find! ( name -- word )
    forth:find [ epr " ?" panic ] ;unless
;


LEXI [forth] REFER [forth] EDIT

: prim>code 1 << 1 or ;
: prim, prim>code , ;


LEXI [forth] REFER [core] EDIT

: LIT,   2 prim, ;
: RET,   3 prim, ;
: +,     8 prim, ;
: JMP,  16 prim, ;
: ZJMP, 17 prim, ;
: @,    18 prim, ;
: !,    19 prim, ;



( ----- stream ----- )

LEXI [forth] REFER [forth] EDIT

COVER

    ( ----- token buffer ----- )
    32      as: len
    len 1 - as: max
    var: buf
    var: bufmax

    var: source
    var: stream   # q: source -- c source
    var: peeked

    : fetch source stream call source! ; # -- c
    : peek peeked ?dup [ fetch dup peeked! ] unless ;
    : take peek no peeked! ;

    : space? 0 ;eq 32 ;eq 10 ;eq no ; # c -- yes | c no

    : skip-spaces ( -- c )
        [ peek
            0 [ STOP ] ;case
            space? [ take drop GO ] ;when
            drop STOP
        ] while
    ;

    var: bp ( buffer pointer )
    : fin 0 bp b! ;
    : check bp bufmax > [ fin buf epr " ...Too long" panic ] ;when ;
    : >buf check bp b! bp inc bp! ;
    
    : read ( -- buf )
        stream [ "No stream" panic ] ;unless
        skip-spaces buf bp!
        [ take
            space? [ fin STOP ] ;when
            >buf GO
        ] while
        buf
    ;

    : handle-num forth:mode [ LIT, , ] [ ( n -- n ) ] if ;

    : notfound ( name -- ) epr " ?" panic ;

    : tk>hex ( tk -- n yes | no )
        # prefix: 0x
        dup b@ CHAR: 0 = [ drop no ] ;unless inc
        dup b@ CHAR: x = [ drop no ] ;unless inc
        s>hex
    ;

    : parse-string
        forth:mode [ JMP, here 0 , here swap ] [ here ] if
        take drop ( skip first double quote )
        [ take
            0  [ "Unclosed string" panic STOP ] ;case
            CHAR: " [ STOP ] ;case
            dup CHAR: \\ = [
                drop ' take c:escaped
                [ "Escape sequence required" panic STOP ] ;unless
                b, GO
            ] ;when
            b, GO
        ] while
        0 b, here:align!
        forth:mode [ here swap ! LIT, , ] when
    ;


SHOW

    max as: forth:max-len

    [ buf IF RET THEN len allot buf! buf max + bufmax! ] >init

TEMPORARY [core] EDIT
    defer: forth:notfound ( name -- )
    ' notfound -> forth:notfound
END


TEMPORARY [core] EDIT
    : forth:take take ;
    : forth:read ( -- buf yes | no )
        read dup b@ IF yes ELSE drop no THEN
    ;
END

    defer: forth:handle-num
    ' handle-num -> forth:handle-num

    defer: forth:parse-string
    ' parse-string -> forth:parse-string

    : forth:run ( source stream -- )
        source >r stream >r stream! source!
        [ skip-spaces
            # prefix
            peek
            CHAR: " [ forth:parse-string GO ] ;case
            drop
            # word
            forth:read [ STOP ] ;unless
            forth:find
            ( found )
            [ dup forth:immed? [
                    forth:code call GO
                ] [
                    forth:code forth:mode IF , ELSE call THEN GO
                ] if
            ] ;when
            drop
            ( dec )
            buf s>dec [ forth:handle-num GO ] ;when
            ( hex )
            buf tk>hex [ forth:handle-num GO ] ;when
            ( not found )
            buf forth:notfound STOP
        ] while
        r> stream! r> source!
    ;

    : forth:eval ( s -- )
        [ ( str -- c str+ ) dup b@ tuck IF inc THEN ] forth:run
    ;

END

: lexi:each ( q -- ) # q: lexi --
    lexisp @ cell - [ ( q sp )
        dup lexicons @ < [ 2drop STOP ] ;when
        2dup >r >r @ swap call
        r> r> cell - GO
    ] while
;

: lexi:clear ( adr -- )
    lexi:hashd hashd-len [  ( hashd i )
        cells over + 0 swap !
    ] for drop
;

: forth:each-word ( lexi q -- ) # q: &entry --
    swap lexi:hashd hashd-len [ ( q hashd i )
        cells over + @ swap >r [ ( q latest )
            0 [ STOP ] ;case
            2dup forth:next >r >r swap call r> r> GO
        ] while r>
    ] for 2drop
;



( ===== Root ===== )

LEXI [forth] REFER [root] EDIT

: CONTEXT ( -- 0 lexi ... )
    0 [ ( no-op ) ] lexi:each
;

: MORE ( 0 lexi ... -- )
    [ ?dup [ ALSO GO ] [ STOP ] if ] while
;

: ORDER ( 0 lexi ... -- )
    lexicons @ lexisp ! MORE
;

: ?words
    "current: " pr CURRENT lexi:name prn
    [ dup "===== " pr lexi:name pr " =====" prn
        [ dup forth:hidden? [ drop ] ;when
            forth:name pr space
        ] forth:each-word cr
    ] lexi:each
;

: ?lexi
    "LEXI" pr space
    [ lexi:name pr space ] lexi:each
    "ORDER" pr space
    CURRENT lexi:name pr space
    "EDIT" prn
;

: LEXI ( -- 0 ) 0 ;
: REFER ( lexicons -- ) [core] [root] ORDER ;

[core] EDIT
: TEMPORARY ( -- lexicons current q ) CONTEXT CURRENT [ EDIT ORDER ] ;



( ===== Include ===== )

LEXI [forth] REFER [core] EDIT

TEMPORARY [file] ALSO
: include ( fname -- )
    "r" file:open! dup >r
    [ ( id -- c id ) dup file:getc swap ] forth:run
    r> file:close!
;
END

: include:
    forth:read [ "File name required" panic ] ;unless
    include
;



( ===== Forth Utils ===== )

LEXI [forth] REFER [core] EDIT

: ;0 ( ? -- ) IF ELSE rdrop THEN ;

: forth:read-find ( -- &entry yes | no )
    forth:read [ "Word name required" eprn no ] ;unless
    forth:find [ epr " ?" eprn no ] ;unless
    yes
;

: word' <IMMED>
    forth:read-find ;0
    forth:mode [ LIT, , ] when
;

: ' <IMMED>
    forth:read-find ;0
    forth:code
    forth:mode [ LIT, , ] when
;

: POSTPONE: <IMMED>
    forth:read-find ;0
    forth:code
    forth:mode [ , ] [ call ] if
;

: COMPILE: <IMMED>
    forth:read-find ;0
    forth:code LIT, , ' , ,
;



( ===== String ===== )

LEXI [forth] REFER [core] EDIT


: CHAR: <IMMED>
    forth:read [ "A character required" panic ] ;unless
    dup b@ dup CHAR: \\ = [ drop inc
        [ [ inc ] [ b@ ] biq ] c:escaped
        [ "Escape sequence required" panic ] ;unless
    ] when nip
    forth:mode [ LIT, , ] when
;



( ===== 0b: binary ===== )

COVER
    var: acc
    var: p
    : next p dup inc p! b@ ;
    : parse
        [ next
          0 [ STOP ] ;case
          CHAR: 0 [ acc 1 <<      acc! GO ] ;case
          CHAR: 1 [ acc 1 << 1 or acc! GO ] ;case
          "Not 0|1" panic
        ] while
    ;
SHOW
    : 0b <IMMED>
        0 acc!
        forth:read [ "binary required" panic ] ;unless p!
        parse
        acc forth:mode [ LIT, , ] when
    ;
END



( ===== Require ===== )

LEXI REFER [core] EDIT

COVER

    var: len
    var: path
    [ len IF RET THEN 256 dup len! allot path! ] >init

    0 var> required

    : next  @ ;
    : next! ! ;
    : name  cell + @ ;
    : name! cell + ! ;
    : fin  2 cells + @ ;
    : fin! 2 cells + ! ;
    : req 3 cells ;

    TEMPORARY [file] ALSO
    : >path ( fname -- )
        dup file:exists? [ epr ": not found" panic ] ;unless
        path len file:fullpath [ path epr ": not found" panic ] ;unless
    ;
    END

    : check-circular ( req -- )
        fin [
            " | " epr path eprn
            required [
                0 [ STOP ] ;case
                " | " epr dup name eprn
                next GO
            ] while
            "Circular dependency detected" panic
        ] unless
    ;

    : find ( -- yes:found | req no )
        required [
            0 [ no STOP ] ;case
            dup name path s= [ yes STOP ] ;when
            next GO
        ] while
        [ check-circular yes ] [ no ] if
    ;

    : create ( fname -- found? )
        >path
        find [ no ] ;when
        path s:put here:align!
        req allot tuck name!
        no over fin!
        required over next! required!
        yes
    ;

    : start ( fname -- )
        create [ ( noop ) ] ;unless
        required >r path include r> yes swap fin!
    ;


SHOW

    : require ( fname -- ) start ;

    : require: ( fname: -- )
        forth:read [ "Source name required" panic ] ;unless
        require
    ;

END



( ===== Syntax ===== )

LEXI [forth] REFER [core] EDIT

TEMPORARY [forth] EDIT
: (:) ( name -- q )
    forth:create
    forth:latest forth:hide!
    forth:compile-mode forth:mode!
    [
        RET,
        forth:latest forth:show!
        forth:run-mode forth:mode!
    ]
;
END

: : ( name: -- q )
    forth:read [ "Word name required" panic ] unless
    (:)
;

: ; <IMMED> ( q -- ) >r ;


: <IMMED> <IMMED> forth:latest forth:immed! ;



: [ <IMMED> ( -- &q &back mode close | &q mode close )
    forth:mode [ JMP, here 0 , here swap ] [ here:align! here ] if
    forth:mode forth:compile-mode forth:mode!
    [
        RET,
        dup forth:mode!
        [ here swap ! LIT, , ] when
    ]
;

: ] <IMMED> ( q -- ) >r ;

: [do <IMMED> forth:mode 0 forth:mode! [ forth:mode! ] ;


: IF   <IMMED> ZJMP, here 0 , ;                 # -- &back
: ELSE <IMMED> JMP, here swap 0 , here swap ! ; # &back -- &back
: THEN <IMMED> here swap ! ;                    # &back --

: AGAIN <IMMED> JMP, forth:latest forth:code , ;

: RECUR <IMMED> forth:latest forth:code , ;


: doconst ( v -- )
    # will be used for patching const
    forth:mode [ LIT, , ] when
;

: as:
    forth:read [ "Const name required" panic ] ;unless
    forth:create
    forth:latest forth:immed!
    LIT, , JMP, ' doconst ,
;

: lexicon:
        lexi:new dup POSTPONE: as: forth:latest forth:name swap lexi:name!
;

: defer:
    forth:read [ "Defered name required" panic ] ;unless
    forth:create
    JMP, 0 ,
;

: END <IMMED> ( q -- ) >r ;



( ===== Comment ===== )

LEXI REFER [root] EDIT

: ( <IMMED>
    [ forth:take
        0 [ "Unclosed comment" panic STOP ] ;case
        CHAR: ) [ STOP ] ;case
        drop GO
    ] while
;


: # <IMMED>
    [ forth:take
        0  [ STOP ] ;case
        10 [ STOP ] ;case
        drop GO
    ] while
;



( ===== COVER SHOW/HIDE with lexicon ===== )

LEXI [forth] REFER [core] EDIT

COVER

    var: public
    var: private

SHOW

    : SHOW public  EDIT ;
    : HIDE private EDIT ;

    : COVER ( -- prev-priv pre-pub q )
        private public
        lexi:new private!
        CURRENT  public!
        private dup ALSO EDIT
        [ PREVIOUS SHOW public! private! ]
    ;

END



( ===== Initializer ===== )

LEXI REFER [core] EDIT

COVER

    init:link as: link

SHOW

    : >init ( xt -- )
        here link @ , link ! ,
    ;

    : init:run
        link @ [
            0 [ STOP ] ;case
            dup cell + @ call @ GO
        ] while
    ;

END



( ===== Struct ===== )

LEXI [forth] REFER [core] EDIT

COVER

    var: latest

    "01234567890123456789012345678901" as: buf

    : close ( -- &back offset ) swap ! ;

    : name   latest forth:name 1 + ;
    : copy   name buf s:copy ;
    : offset latest forth:code cell + @ ;
    : getter copy buf ;
    : setter getter dup "!" s:append! ;

SHOW

    : STRUCT: ( -- &back offset q )
        # LIT n RET
        forth:read [ "struct name required" panic ] ;unless
        forth:create
        LIT, here 0 , RET,
        0 ' close
    ;

    : field: ( offset q n -- offset+n q)
        forth:read [ "field name required" panic ] ;unless
        forth:create
        swap >r over
        LIT, , JMP, [ + ] ,
        + r>
        forth:latest latest!
    ;

    : cell: ( offset q -- offset+n q ) cell field: ;

    : :get getter forth:create LIT, offset , JMP, [ + @ ] , ;
    : :set setter forth:create LIT, offset , JMP, [ + ! ] , ;
    : :access :get :set ;

END



( ===== Test ===== )

LEXI REFER [core] EDIT

: ASSERT ( v s )
    swap IF drop ELSE "Assertion failed: " epr panic THEN
;

: CHECK ( s q -- ) # q: -- ok?
    # Call q then check TOS is true and sp is balanced
    # or die with printing s.
    # Quotation q should not remain values on rstack

    swap >r >r sp r> swap >r ( r: s sp )
    call

    # check stack balacne first to avoid invalid result
    sp cell + ( sp + result )
    r> != IF "Stack imbalance: " epr r> panic THEN

    # check result
    not IF "Failed: " epr r> panic THEN

    # drop description
    rdrop
;

: clean? ( q -- )
        >r sp r> swap >r call sp r> =
;

: CLEAN ( q s -- )
        >r clean? r> swap [ drop ] [ panic ] if
;



( ===== Var ===== )

LEXI [forth] REFER [core] EDIT

: var>
    forth:read [ "Var name required" panic ] ;unless
    forth:max-len dec s:check [ epr ": too long var name" panic ] ;unless
    dup >r forth:create
    LIT, here swap , RET,
    r> dup "!" s:append! forth:create
    LIT, , !, RET,
;

: var: 0 ' var> call ;

: var' <IMMED>
    forth:read [ "Var name required" panic ] ;unless
    forth:find [ " ?" epr panic ] ;unless
    forth:code cell +
    forth:mode [ LIT, , ] ;when
;


: 2nd@ ( xt -- v ) cell + @ ;
: 2nd! ( v xt -- ) cell + ! ;

: -> <IMMED>
    forth:read-find [ "Word name required" panic ] ;unless
    forth:code
    forth:mode [ LIT, , COMPILE: 2nd! ] [ 2nd! ] if
;



( ===== Primitives ===== )

LEXI [forth] REFER [core] EDIT

COVER

    : compile-only ( prim -- ) forth:mode [ prim, ] [ "Compile Only" panic ] if ;
    : primitive ( prim q -- ) forth:mode [ drop prim, ] [ nip call ] if ;

SHOW

    : noop <IMMED> ;
    : HALT <IMMED> 1 [ HALT ] primitive ;
    : LIT  <IMMED> 2 compile-only ;
    : RET  <IMMED> 3 compile-only ;

    : dup  <IMMED> 4 [ dup  ] primitive ;
    : drop <IMMED> 5 [ drop ] primitive ;
    : swap <IMMED> 6 [ swap ] primitive ;
    : over <IMMED> 7 [ over ] primitive ;

    : +    <IMMED> 8  [ +    ] primitive ;
    : -    <IMMED> 9  [ -    ] primitive ;
    : *    <IMMED> 10 [ *    ] primitive ;
    : /mod <IMMED> 11 [ /mod ] primitive ;

    : =  <IMMED> 12 [ =  ] primitive ;
    : != <IMMED> 13 [ != ] primitive ;
    : >  <IMMED> 14 [ >  ] primitive ;
    : <  <IMMED> 15 [ <  ] primitive ;

    : JMP  <IMMED> 16 compile-only ;
    : ZJMP <IMMED> 17 compile-only ;

    : @  <IMMED> 18 [ @  ] primitive ;
    : !  <IMMED> 19 [ !  ] primitive ;
    : b@ <IMMED> 20 [ b@ ] primitive ;
    : b! <IMMED> 21 [ b! ] primitive ;

    : and <IMMED> 22 [ and ] primitive ;
    : or  <IMMED> 23 [ or  ] primitive ;
    : inv <IMMED> 24 [ inv ] primitive ;
    : xor <IMMED> 25 [ xor ] primitive ;

    : lsft <IMMED> 26 [ lsft ] primitive ;
    : asft <IMMED> 27 [ asft ] primitive ;

    : io <IMMED> 28 [ io ] primitive ;

    : >r    <IMMED> 29 compile-only ;
    : r>    <IMMED> 30 compile-only ;
    : rdrop <IMMED> 31 compile-only ;

    : sp  <IMMED> 32 [ sp  ] primitive ;
    : sp! <IMMED> 33 [ sp! ] primitive ;
    : rp  <IMMED> 34 [ rp  ] primitive ;
    : rp! <IMMED> 35 [ rp! ] primitive ;

END



( ===== Loadfile ===== )

LEXI REFER [core] EDIT

# loadfile ( path -- addr )
# loadfile: ( :path -- addr )
# addr:
#   0x00 size
#   0x04 data...
#        0000 ( null terminated, aligned )


COVER

    var: id
    var: addr
    var: size

SHOW

    TEMPORARY [file] ALSO
    : loadfile ( path -- addr )
        "rb" file:open! id!
        id file:size size!
        here addr!
        size ,
        here size id file:read!
        here size + here!
        0 b, here:align!
        id file:close!
        addr
    ;
    END

    : loadfile: ( :path -- addr )
        forth:read [ "file name required" ] ;unless
        loadfile
    ;

    : filesize @ ;      # & -- n
    : filedata cell + ; # & -- &data

END



( ===== CLI Option ===== )

LEXI REFER [core] EDIT

COVER

    256 as: len
    var: buf
    var: argc
    var: included

    : read buf swap len cli:get-arg [ "too long option" panic ] unless ;

    [ buf IF RET THEN len allot buf! ] >init

SHOW

    var: opt:repl
    var: opt:argi

    : opt:parse-all
        yes opt:repl!
        cli:argc 2 < IF RET THEN

        no opt:repl!
        no included!
        cli:argc dec argc!
        argc [ included [ drop ] ;when
            inc dup read inc opt:argi!
            buf "--repl" s= [ yes opt:repl! ] ;when
            buf "--quit" s= [ no  opt:repl! ] ;when
            buf include
            yes included!
        ] for
    ;

    : opt:read! ( -- buf yes | no )
        opt:argi cli:argc >= [ no ] ;when
        opt:argi read buf yes
        opt:argi inc opt:argi!
    ;

END



( ===== Turnkey Image ===== )

LEXI [forth] [file] REFER [core] EDIT

COVER

    var: id
    defer: main
    : set-boot! ( adr )
        -> main
        [ # Decrement argi: bin/arkam forth.ark app.f => bin/arkam app.ark
            opt:argi dec opt:argi!
            main bye
        ] 0x04 !
    ;

SHOW

    : save-image ( fname -- )
        "wb" file:open! id!
        # zero clear 0x00-0x03
        0 here ! here 4 id file:write!
        # write current image
        0x04 here id file:write!
        id file:close!
    ;

    : turnkey ( fname adr -- )
        set-boot! save-image
    ;

    : turnkey: ( adr fname: -- )
        forth:read [ "Image name required" panic ] ;unless
        swap turnkey
    ;

END



( ===== REPL ===== )

LEXI REFER [core] EDIT
lexicon: [repl]

LEXI [repl] [sys] [forth] REFER [repl] EDIT

COVER

    256 as: len
    255 as: max
    var: buf
    var: show-depth
    var: show-stack

    : prompt
        show-stack [ "| " pr ?stack ] when
        show-depth [ sys:depth .. ] when
        "> " pr
    ;
    : listen buf len getline IF buf ELSE " " THEN forth:eval ;

    : notfound ( name -- ) epr " ?" eprn ;

    : lexicons
        # create [user] lexicon into [core] then refer and switch to it
        LEXI REFER [core] EDIT
        "[user]" lexi:create
        dup "[user]" forth:create LIT, , RET,
        dup ALSO EDIT
    ;

SHOW

    ' notfound -> forth:notfound
    : repl:init len allot buf! lexicons ;
    : repl:hide-depth! no  show-depth! ;
    : repl:show-depth! yes show-depth! ;
    : repl:hide-stack! no  show-stack! ;
    : repl:show-stack! yes show-stack! ;
    : repl [ prompt listen GO ] while ;

END



LEXI [repl] REFER [core] EDIT

: main
    init:run
    opt:parse-all
    opt:repl [
        repl:init
        repl:show-depth!
        repl
    ] when
    bye
;


LEXI REFER [core] EDIT
