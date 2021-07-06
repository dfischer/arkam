require: lib/core.f


val: verbose  no verbose!

: [verbose <IMMED>
  verbose IF [ ( noop ) ] RET THEN
  [ in:read [ "close quot required" panic ] unless
    "]" s= IF STOP RET THEN
    GO
  ] while
;



( ===== Image area and There pointer ===== )

: kilo 1000 * ;
256 kilo        as: image_max
image_max allot as: there


( memory layout )

0x04 as: addr_start
0x08 as: addr_here
0x10 as: addr_begin


( relative pointer )

val: mhere

: m>t there + ; # &meta -- &there
: t>m there - ; # &there -- &meta

: m@  m>t @ ;
: m!  m>t ! ;
: bm@ m>t b@ ;
: bm! m>t b! ;

: mhere! ( adr -- )
  dup 0             <  IF .. "invalid mhere" panic THEN
  dup image_max - 0 >= IF .. "invalid mhere" panic THEN
  dup mhere!
  addr_here m!
;


: mhere:align! mhere align mhere! ;

: m,  mhere m!  mhere cell + mhere! ;
: bm, mhere bm! mhere inc    mhere! ;

: m0pad 0 bm, mhere:align! ;

: entrypoint! ( madr -- ) addr_start m! ;

: image_size mhere m>t there - ;

( initialize )
addr_begin mhere!


( ----- save ----- )

MODULE

  val: id

---EXPOSE---

  : save ( fname -- )
    "wb" file:open! id!
    there image_size id file:write!
    id file:close!
  ;

  : save: ( fname: -- )
    in:read [ "out name required" panic ] unless
    save
  ;
END


( ===== Meta Dictionary ===== )

val: mlatest  mhere mlatest!


( ===== debug ===== )

: mdump ( madr len -- ) [ m>t ] dip dump ;
: minfo
  "there 0x" pr there ?hex drop cr
  "here  0x" pr mhere ?hex drop cr
  "start 0x" pr addr_start m@ ?hex drop cr
;

( ===== prim ===== )

: prim ( n -- code ) 1 << 1 or ;
: prim, ( n -- ) prim m, ;


mhere entrypoint!
2 prim, 42 m, 1 prim,

minfo
0 64 mdump
save: out/tmp.ark
bye

MODULE

8 as: left

: pad ( s -- s )
  dup s:len left swap - [ " " epr ] times
;

: prim: ( n -- n+ ) dup as:
  [verbose forth:latest forth:name pad epr " " epr forth:latest forth:xt . ]
  inc
;

---EXPOSE---

[verbose "PRIMITIVES" eprn ]

0
prim: NOOP
prim: HALT
prim: LIT
prim: RET

prim: DUP
prim: DROP
prim: SWAP
prim: OVER

prim: ADD
prim: SUB
prim: MUL
prim: DMOD

prim: EQ
prim: NEQ
prim: GT
prim: LT

prim: JMP
prim: ZJMP

prim: GET
prim: SET
prim: BGET
prim: BSET

prim: AND
prim: OR
prim: NOT
prim: XOR
prim: LSHIFT
prim: ASHIFT

prim: IO

prim: RPUSH
prim: RPOP
prim: RDROP

prim: GETSP
prim: SETSP
prim: GETRP
prim: GETSP

drop

END
