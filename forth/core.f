# ===== Forth Core =====



# ----- Memory Layout -----
# 0x04 &start
# 0x08 here
# 0x0C latest
# 0x10 begin

: here    0x08 @ ;
: here!   0x08 ! ;



( ===== Boolean ===== )

-1 as: ok
 0 as: ng

ok as: yes
ng as: no

ok as: true
ng as: false

ok as: GO
ng as: STOP


: not 0 != ;



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

PRIVATE
  : loop ( q n ) dup 1 < IF 2drop RET THEN
    1 - over swap >r >r call r> r> AGAIN
  ;
PUBLIC
  : times ( n q -- ) swap loop ;
END


PRIVATE
  : loop ( q n i )
    2dup <= IF 3drop RET THEN
    swap over 1 +     # q i n i+1
    >r >r swap dup >r # i q | i+1 n q
    call r> r> r> AGAIN
  ;
PUBLIC
 : for ( n q -- ) swap 0 loop ;
END


PRIVATE
  : loop ( q n )
    dup 1 < IF 2drop RET THEN
    dec 2dup >r >r swap call r> r> AGAIN
  ;
PUBLIC
  : for- ( n q -- ) swap loop ;
END


: while ( q -- )
  # loop while q put yes to TOS
  dup >r call IF r> AGAIN THEN rdrop
;



( ===== System ===== )

PRIVATE
  : query 0 io ;
PUBLIC
  : sys:size 0 query ;
  : sys:ds_size 2 query ;
  : sys:ds      3 query ;
  : sys:rs_size 4 query ;
  : sys:rs      5 query ;
  : sys:cell_size 6 query ;
  : sys:max_int 7 query ;
  : sys:min_int 8 query ;
  ( calculated )
  : sys:ds_base sys:ds_size cells sys:ds + ;
  : sys:depth sp cell + sys:ds_base swap - cell / ; # order matters
  : sys:ds0! sys:ds_base cell - sp! ;
END



( ===== Stdio ===== )

# port 1:stdout 2:stderr
: stdio:ready? -1 1 io ; # -- ?
: putc          0 1 io ; # c --
: getc          1 1 io ; # -- c
: stdio:port    2 1 io ; # -- p
: stdio:port!   3 1 io ; # p --


1 as: stdout
2 as: stderr


: cr    10 putc ;
: space 32 putc ;


: pr ( s -- )
  dup b@ dup 0 = [ 2drop ] ;when
  putc 1 + AGAIN
;

: prn ( s -- ) pr cr ;


: call/port ( q p -- ) stdio:port >r stdio:port! call r> stdio:port! ;
  # call-with-port
  # call q with port p then restore previous port

: >stdout ( q -- ) stdout call/port ;
: >stderr ( q -- ) stderr call/port ;


: epr  ( s -- ) [ pr  ] >stderr ;
: eprn ( s -- ) [ prn ] >stderr ;


: getline ( buf len -- success? )
  swap ( len buf )
  [ over 1 < [ ng STOP ] ;when
    getc ( len buf c )
    0  [ 0 swap b! drop ok STOP ] ;case
    10 [ 0 swap b! drop ok STOP ] ;case
    over b! &dec &inc bi* GO
  ] while
;


: die 1 HALT ;

defer: panic
: (panic) eprn die ;
&(panic) is: panic



( ===== Debug print ===== )

: >hex ( n -- c ) dup 10 < IF 48 ELSE 55 THEN + ;

: ?h "HERE" prn ;

PRIVATE

  11 as: max ( i32: max "-2147483648" )
  val: buf
  val: n
  val: posi
  val: base
  val: q
  val: r
  val: i

  : init buf ?dup [ max 1 + allot dup buf! ] unless max + i! ;
  : check buf i > IF "too big num" panic THEN ;
  : put i 1 - i! i b! ; # c --
  : put_sign posi IF RET THEN 45 put ;
  : check_sign n 0 < IF n neg n! no ELSE yes THEN posi! ;
  : read n base /mod r! q!
    r >hex put
    q 0 = IF RET THEN q n! AGAIN
  ;
  : check_min ( minimum number )
    n 0 = IF "0" pr space rdrop RET THEN
    n dup neg != IF RET THEN ( 0x80000000 * -1 = 0x80000000 )
    10 base = IF "-2147483648" pr space rdrop RET THEN
    16 base = IF "-80000000"   pr space rdrop RET THEN
    "?: invalid base" panic
  ;
  : go ( n -- )
    n! check_min check_sign init read put_sign i pr space
  ;

PUBLIC

  : ?    dup 10 base! go ;
  : ?hex dup 16 base! go ;

END


: .. ? drop ;
: . .. cr ;


: ?stack ( -- )
  [ sp cell + ( adr )
    sys:depth dec [ ( adr i )
      cells over + @ ..
    ] for- drop
    cr
  ] >stderr
;



( ===== String ===== )

: s= ( s1 s2 -- ? )
  [ 2dup [ b@ ] bia over != # s1 s2 c diff?
    ( diff ) [ 3drop no STOP ] ;when
    ( end  ) 0 [ 2drop yes STOP ] ;case drop
    ( next ) &inc bia GO
  ] while
;


: c:digit? ( c -- ? ) dup 48 < [ drop no ] [ 57  <= ] if ;
: c:upper? ( c -- ? ) dup 65 < [ drop no ] [ 90  <= ] if ;
: c:lower? ( c -- ? ) dup 97 < [ drop no ] [ 122 <= ] if ;

: c>dec ( c -- n yes | no ) dup c:digit? [ 48 - yes ] [ drop no ] if ;

: s>dec ( s -- n yes | no )
  dup b@ 45 = IF inc -1 ELSE 1 THEN swap ( sign s )
  0 swap ( sign acc s )
  [ dup b@
    0 [ drop yes STOP ] ;case
    c>dec [ pullup 10 * + swap inc GO ] ;when
    drop no STOP
  ] while ( sign acc dec? )
  IF * yes ELSE 2drop no THEN
;


: s:each ( s q -- ) # q: ( c -- )
  swap
  [ dup b@ ( q s c )
    0 [ 2drop STOP ] ;case
    swap inc >r swap dup >r call r> r> GO
  ] while
;

: s:put ( s -- )
  [ b, ] s:each 0 b,
;


( ===== File ===== )

PRIVATE
  : query    8 io ;
PUBLIC
  : file:ready?  -1 query ; # -- ?
  : file:open     0 query ; # path mode -- id ok | ng
  : file:close    1 query ; # id -- ?
  : file:read     2 query ; # buf len id -- ?
  : file:write    3 query ; # buf len id -- ?
  : file:seek     4 query ; # id offset origin -- ?
  : file:exists?  5 query ; # path -- ?
  : file:getc     6 query ; # id -- c | 0
  : file:peek     7 query ; # id -- c | 0
  : file:fullpath 8 query ; # path buf max -- ?
  : file:size     9 query ; # id -- n
  ( --- defensive --- )
  : file:open!  file:open [ "Can't open " epr eprn die ] unless ; # path mode -- id
  : file:close! file:close drop ; # id --
  : file:read!  file:read  IF RET THEN "Can't read" panic ;
  : file:write! file:write IF RET THEN "Can't write" panic ;
END



( ===== CLI ===== )

: cli:query 12 io ;
: cli:argc    0 cli:query ; # -- n
: cli:get_arg 1 cli:query ; # buf i len -- ?

: cli:get_arg! ( buf i len -- )
  cli:get_arg IF RET THEN "Can't get arg!" panic
;



( ===== Forth ===== )

val: forth:mode
1 as: forth:compile_mode
0 as: forth:run_mode

0x01 as: flag_immed
0x02 as: flag_hidden
0x03 as: flags

: forth:latest  0x0C @ ;
: forth:latest! 0x0C ! ;

# Dictionary
# | next:30 | hidden:1 | immed:1  tagged 32bit pointer
# | &name
# | &code
# | code...

: forth:next  @ flags off ; # &entry -- &entry
: forth:next! !           ; # &next &entry --

: forth:name  cell + @    ; # &entry -- &name
: forth:name! cell + !    ; # &name -- &entry

: forth:code  2 cells + @ ; # &entry -- &code
: forth:code! 2 cells + ! ; # &code &entry --

: forth:hide! flag_hidden on!  ; # &entry --
: forth:show! flag_hidden off! ; # &entry --
: forth:hidden? @ flag_hidden and ; # &entry -- ?

: forth:immed!     flag_immed on!  ; # &entry --
: forth:non-immed! flag_immed off! ; # &entry --
: forth:immed? @ flag_immed and ; # &entry -- ?

: forth:create ( name -- )
  here:align! here >r s:put here:align! r> ( &name )
  ( latest ) here forth:latest , forth:latest!
  ( &name  ) ,
  ( &code  ) here cell + ,
;


defer: forth:find
: forth:(find) ( name -- name 0 | normal: &entry 1 | immed: &entry 2 )
  forth:latest [ # name latest
    ( notfound ) 0 [ no STOP ] ;case
    ( hidden   ) dup forth:hidden? [ forth:next GO ] ;when
    ( found    ) 2dup forth:name s=
                 [ nip dup forth:immed? IF 2 ELSE 1 THEN STOP ] ;when
    ( next     ) forth:next GO
  ] while
;
&forth:(find) is: forth:find

: forth:find! ( name -- normal: &entry 1 | immed: &entry 2 )
  forth:find [ epr " ?" panic ] ;unless
;


: prim>code 1 << 1 or ;
: prim, prim>code , ;
: LIT,   2 prim, ;
: RET,   3 prim, ;
: +,     8 prim, ;
: JMP,  16 prim, ;
: ZJMP, 17 prim, ;


( ----- stream ----- )

PRIVATE

  32      as: len
  len 1 - as: max
  val: buf
  : buf buf ?dup IF RET THEN len allot dup buf! ;

  val: source
  val: stream   # q: source -- c source

  : take source stream call source! ; # -- c

  : space? 0 ;eq 32 ;eq 10 ;eq no ; # c -- yes | c no

  : skip_spaces ( -- c )
    [ take
      0 [ 0 STOP ] ;case
      space? [ GO ] ;when
      STOP
    ] while
  ;

  : read ( -- buf )
    stream [ "No stream" panic ] ;unless
    skip_spaces max swap buf swap ( n buf c )
    [ >r over r> ( n buf+ n c )
      0 [ drop 0 swap b! drop buf STOP ] ;case
      swap 0 = [ 3drop buf epr " ...Too long" panic STOP ] ;when
      space? [ 0 swap b! drop buf STOP ] ;when
      over b! &dec &inc bi* take GO
    ] while
  ;

  : handle_num forth:mode [ LIT, , ] [ ( n -- n ) ] if ;

  : notfound ( name -- ) epr " ?" panic ;

PUBLIC

  defer: forth:notfound ( name -- )
  &notfound is: forth:notfound

  : forth:stream  stream  ;
  : forth:stream! stream! ;
  : forth:source  source  ;
  : forth:source! source! ;
  : forth:take    take ;
  : forth:read ( -- buf yes | no )
    read dup b@ IF yes ELSE drop no THEN
  ;

  defer: forth:handle_num
  &handle_num is: forth:handle_num

  : forth:run ( source stream -- )
    source >r stream >r stream! source!
    [ forth:read [ STOP ] ;unless
      forth:find
      ( found )
      2 [ forth:code call GO ] ;case
      1 [ forth:code forth:mode IF , ELSE call THEN GO ] ;case
      2drop
      ( num )
      buf s>dec [ forth:handle_num GO ] ;when
      ( not found )
      buf forth:notfound STOP
    ] while
    r> stream! r> source!
  ;

  : forth:eval ( s -- )
    [ ( str -- str+ ) dup b@ tuck IF inc THEN ] forth:run
  ;

END


: forth:words
  forth:latest [
    0 [ STOP ] ;case
    dup forth:hidden? [ forth:next GO ] ;when
    dup forth:name pr space
    forth:next GO
  ] while cr
;


: include ( fname -- )
  "r" file:open! dup >r
  [ ( id -- c id ) dup file:getc swap ] forth:run
  r> file:close!
;

: include:
  forth:read [ "File name required" panic ] ;unless
  include
;



( ===== Forth Utils ===== )

: ;0 ( ? -- ) IF ELSE rdrop THEN ;

: forth:read_find ( -- &entry yes | no )
  forth:read [ "Word name required" eprn no ] ;unless
  forth:find [ epr " ?" eprn no ] ;unless
  yes
;

: ' <IMMED>
  forth:read_find ;0
  forth:code
  forth:mode [ LIT, , ] when
;

: POSTPONE: <IMMED>
  forth:read_find ;0
  forth:code
  forth:mode [ , ] [ call ] if
;

: COMPILE: <IMMED>
  forth:read_find ;0
  forth:code LIT, , &, ,
;



( ===== String ===== )

: " <IMMED>
  forth:mode [ JMP, here 0 , here swap ] [ here ] if
  [ forth:take
    0  [ "Unclosed string" panic ] ;case
    34 [ STOP ] ;case
    b, GO
  ] while
  0 b, here:align!
  forth:mode [ here swap ! LIT, , ] when
;



( ===== Syntax ===== )

x: : ( name: -- q )
  forth:read [ "Word name required" panic ] unless
  forth:create
  forth:latest forth:hide!
  forth:compile_mode forth:mode!
  [
    RET,
    forth:latest forth:show!
    forth:run_mode forth:mode!
  ]
;

x: ; <IMMED> ( q -- ) >r ;


x: <IMMED> <IMMED> forth:latest forth:immed! ;


x: [ <IMMED> ( -- &q &back mode close | &q mode close )
  forth:mode [ JMP, here 0 , here swap ] [ here:align! here ] if
  forth:mode forth:compile_mode forth:mode!
  [
    RET,
    dup forth:mode!
    [ here swap ! LIT, , ] when
  ]
;

x: ] <IMMED> ( q -- ) >r ;

: [do <IMMED> forth:mode 0 forth:mode! [ forth:mode! ] ;


x: IF   <IMMED> ZJMP, here 0 , ;                 # -- &back
x: ELSE <IMMED> JMP, here swap 0 , here swap ! ; # &back -- &back
x: THEN <IMMED> here swap ! ;                    # &back --

x: AGAIN <IMMED> JMP, forth:latest forth:code , ;


x: as:
  forth:read [ "Const name required" panic ] ;unless
  forth:create
  forth:latest forth:immed!
  LIT, , JMP, [ ( v -- ) forth:mode [ LIT, , ] when ] ,
;


x: defer:
  forth:read [ "Defered name required" panic ] ;unless
  forth:create
  JMP, 0 ,
;

: is ( xt name -- )
  forth:find [ forth:notfound ] unless
  ( xt &entry ) forth:code cell + !
;

x: is:
  forth:read [ "Defered name required" panic ] unless
  is
;


x: END <IMMED> ( q -- ) >r ;



( ===== Comment ===== )

x: CHAR: <IMMED>
  forth:read [ "A character required" panic ] ;unless
  b@ forth:mode [ LIT, , ] when
;


x: ( <IMMED>
  [ forth:take
    0 [ "Unclosed comment" panic STOP ] ;case
    CHAR: ) [ STOP ] ;case
    drop GO
  ] while
;


x: # <IMMED>
  [ forth:take
    0  [ STOP ] ;case
    10 [ STOP ] ;case
    drop GO
  ] while
;



( ===== Private/Public ===== )

: forth:hide_range ( start end -- )
  # hide  start < word <= end
  [ 2dup = [ 2drop STOP ] ;when
    dup forth:hide! forth:next GO
  ] while
;

x: PRIVATE ( -- start closer )
  forth:latest 
  [ forth:latest forth:hide_range ]
;

x: PUBLIC ( start closer -- start end closer )
  drop forth:latest &forth:hide_range
;



( ===== Struct ===== )

PRIVATE

  : close ( -- &back offset ) swap ! ;

PUBLIC

  : STRUCT ( -- &back offset q )
    # LIT n RET
    forth:read [ "struct name required" panic ] ;unless
    forth:create
    LIT, here 0 , RET,
    0 &close
  ;
  
  : field: ( offset q n -- offset+n q)
    forth:read [ "field name required" panic ] ;unless
    forth:create
    swap >r over
    LIT, , JMP, [ + ] ,
    + r>
  ;

  : cell: ( offset q -- offset+n q ) cell field: ;

END



( ===== CLI Option ===== )

PRIVATE

  64 as: len
  val: buf

  : read buf swap len cli:get_arg [ "too long option" panic ] unless ;

PUBLIC

  val: opt:repl
  : opt:parse_all
    len allot buf!
    yes opt:repl!
    cli:argc 2 < IF RET THEN
    no opt:repl!
    cli:argc dec [
      inc read
      buf "--repl" s= [ yes opt:repl! ] ;when
      buf "--quit" s= [ no  opt:repl! ] ;when
      buf include
    ] for
  ;

END



( ===== REPL ===== )

PRIVATE

  256 as: len
  255 as: max
  val: buf
  val: show_depth
  val: show_stack
  
  : buf buf ?dup [ len allot dup buf! ] unless ;
  
  : prompt
    show_stack [ "| " pr ?stack ] when
    show_depth [ sys:depth .. ] when
    "> " pr
  ;
  : listen buf len getline IF buf ELSE "" THEN forth:eval ;

  : notfound ( name -- ) epr " ?" eprn ;

PUBLIC

  &notfound is: forth:notfound
  : repl:hide_depth! no  show_depth! ;
  : repl:show_depth! yes show_depth! ;
  : repl:hide_stack! no  show_stack! ;
  : repl:show_stack! yes show_stack! ;
  : repl [ prompt listen GO ] while ;

END

: bye 0 HALT ;

: main
  opt:parse_all
  opt:repl [ yes show_depth! repl ] when
  bye
;



( ===== Primitives ===== )

: compile_only ( prim -- ) forth:mode [ prim, ] [ "Compile Only" panic ] if ;
: primitive ( prim q -- ) forth:mode [ drop prim, ] [ nip call ] if ;

x: noop <IMMED> ;
x: HALT <IMMED> 1 [ HALT ] primitive ;
x: LIT  <IMMED> 2 compile_only ;
x: RET  <IMMED> 3 compile_only ;

x: dup  <IMMED> 4 [ dup  ] primitive ;
x: drop <IMMED> 5 [ drop ] primitive ;
x: swap <IMMED> 6 [ swap ] primitive ;
x: over <IMMED> 7 [ over ] primitive ;

x: +    <IMMED> 8  [ +    ] primitive ;
x: -    <IMMED> 9  [ -    ] primitive ;
x: *    <IMMED> 10 [ *    ] primitive ;
x: /mod <IMMED> 11 [ /mod ] primitive ;

x: =  <IMMED> 12 [ =  ] primitive ;
x: != <IMMED> 13 [ != ] primitive ;
x: >  <IMMED> 14 [ >  ] primitive ;
x: <  <IMMED> 15 [ <  ] primitive ;

x: JMP  <IMMED> 16 compile_only ;
x: ZJMP <IMMED> 17 compile_only ;

x: @  <IMMED> 18 [ @  ] primitive ;
x: !  <IMMED> 19 [ !  ] primitive ;
x: b@ <IMMED> 20 [ b@ ] primitive ;
x: b! <IMMED> 21 [ b! ] primitive ;

x: and <IMMED> 22 [ and ] primitive ;
x: or  <IMMED> 23 [ or  ] primitive ;
x: not <IMMED> 24 [ not ] primitive ;
x: xor <IMMED> 25 [ xor ] primitive ;

x: lsft <IMMED> 26 [ lsft ] primitive ;
x: asft <IMMED> 27 [ asft ] primitive ;

x: io <IMMED> 28 [ io ] primitive ;

x: >r    <IMMED> 29 compile_only ;
x: r>    <IMMED> 30 compile_only ;
x: rdrop <IMMED> 31 compile_only ;

x: sp  <IMMED> 32 [ sp  ] primitive ;
x: sp! <IMMED> 33 [ sp! ] primitive ;
x: rp  <IMMED> 34 [ rp  ] primitive ;
x: rp! <IMMED> 35 [ rp! ] primitive ;

