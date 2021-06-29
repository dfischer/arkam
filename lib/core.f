: <IMMED> &handle:immed forth:latest forth:handler! ; <IMMED>


: ?h <IMMED> "HERE" prn ; ( debug )


: # <IMMED>
  ( skip line comment )
  [ in:take
    0  [ STOP ] ;CASE
    10 [ STOP ] ;CASE
    drop GO
  ] while
;



( --- Generic structure closer --- )
: END <IMMED> ( q -- ) >r ;



( ----- Module ----- )

: MODULE ( -- start start closer )
  forth:latest dup
  [ ( start end -- )
    [ 2dup = [ 2drop STOP ] ;IF
      dup forth:hide! forth:next GO
    ] while
  ]
;

: ---EXPOSE--- ( start start closer -- start latest closer )
  nip forth:latest swap ;



( ----- string ----- )


: s:append! ( dst what -- )
  ( no check )
  >r [ dup b@ IF inc GO ELSE STOP THEN ] while r> ( dst what )
  [ 2dup b@ swap over swap b!
    IF &inc bia GO ELSE 2drop STOP THEN
  ] while
;

: s:append ( dst what max -- ? )
  # max includes null termination
  ( check )
  >r 2dup &s:len bia + inc r>
  > [ 2drop ng ] ;IF
  s:append! ok
;


: s:check ( str max -- str ok? )
  # check length
  # max includes null termination
  over s:len 1 + >=
;



( ----- val ----- )

MODULE 

  32 const: len
  len allot const: buf
  len 1 - const: max
  
  : check ( name -- name )
    dup s:len max > IF epr " too long" panic THEN
  ;
  
  : create_getter ( addr -- )
    buf forth:create
    "LIT" forth:compile, , "@" forth:compile, "RET" forth:compile,
  ;
  
  : create_setter ( addr -- )
    buf "!" max s:append drop
    buf forth:create
    "LIT" forth:compile, , "!" forth:compile, "RET" forth:compile,
  ;
  
---EXPOSE---
  
  : val: ( v -- )
    in:read not IF "val name required" panic THEN
    max s:check [ epr " ...too long" panic ] unless
    buf s:copy
    here:align! here swap , dup
    create_getter
    create_setter
  ;
  
END



( ----- words ----- )

: words
  forth:latest [
    0 [ STOP ] ;CASE
    dup forth:hidden? not IF
      dup forth:name pr space
    THEN
    forth:next GO
  ] while
  cr
;



( ----- struct ----- )

MODULE

  : close ( -- word offset ) swap forth:xt! ;

---EXPOSE---

  : STRUCT ( -- word offset q )
    in:read [ "struct name required" panic ] unless
    forth:create
    &handle:data forth:latest forth:handler!
    forth:latest 0 &close
  ;
  
  : field: ( offset q n -- offset+n q)
    in:read [ "field name required" panic ] unless
    forth:create
    swap >r over
    "LIT" forth:compile, , "+" forth:compile, "RET" forth:compile,
    + r>
  ;
  
END
