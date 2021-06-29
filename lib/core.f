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

: close-module ( start end -- )
  [ 2dup = [ 2drop STOP ] ;IF
    dup forth:hide! forth:next GO
  ] while
;

: MODULE ( -- start start closer )
  forth:latest dup &close-module ;

: ---EXPOSE--- ( start start closer -- start latest closer )
  nip forth:latest swap ;



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
    buf [
      dup b@
      0 [ dup 33 ( ! ) swap b! inc 0 swap b! STOP ] ;CASE
      drop inc GO
    ] while
    buf forth:create
    "LIT" forth:compile, , "!" forth:compile, "RET" forth:compile,
  ;

---EXPOSE---

  : val: ( v -- )
    in:read not IF "val name required" panic THEN check
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
