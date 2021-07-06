require: lib/core.f


val: verbose  yes verbose!

: [verbose <IMMED>
  verbose IF [ ( noop ) ] RET THEN
  [ in:read [ "close quot required" panic ] unless
    "]" s= IF STOP RET THEN
    GO
  ] while
;


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
