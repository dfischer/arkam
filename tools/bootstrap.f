require: lib/core.f


val: verbose  yes verbose!

: [verbose <IMMED>
  verbose IF [ ( noop ) ] RET THEN
  [ in:read [ "close quot required" panic ] unless
    "]" s= IF STOP RET THEN
    GO
  ] while
;



( ===== Image area and There pointer ===== )

: kilo 1000 * ;
256 kilo         as: image_size
image_size allot as: image_area


( memory layout )

0x04 as: addr_start
0x08 as: addr_here
0x10 as: addr_begin


( pointer )

val: there   image_area there!
val: mhere

: mhere! dup mhere! there addr_here + ! ; # save mhere at image

: there! ( adr -- )
  dup image_area              <  IF .. "invalid there" panic THEN
  dup image_size - image_area >= IF .. "invalid there" panic THEN
  dup image_area - mhere!
  there!
;

: mhere! ( adr -- ) image_area + there! ;

: there:align! there align there! ;
: t,  there !  there cell + there! ;
: bt, there b! there inc    there! ;

: mhere:align! there:align! ;
: m,  t,  ;
: bm, bt, ;

: m0pad 0 bm, mhere:align! ;

: m>r image_area + ; # &meta -- &real
: r>m image_area - ; # &real -- &meta


: entrypoint! ( adr -- ) addr_start there + ! ;


( initialize )
addr_begin mhere!



( ===== Meta Dictionary ===== )

val: mlatest  mhere mlatest!


( ===== debug ===== )

: mdump ( madr len -- ) [ image_area + ] dip dump ;



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
