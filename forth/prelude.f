: CHAR: <IMMED>
  forth:read [ " A character required" panic ] ;unless
  b@ forth:mode [ LIT, , ] when
;


: ( <IMMED>
  [ forth:take
    0 [ " Unclosed comment" panic STOP ] ;case
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


: ." <IMMED>
  forth:mode [ here ] unless
  POSTPONE: "
  forth:mode [ COMPILE: prn ] [ prn here! ] if
;



: 2nd! ( v xt -- ) cell + ! ;

: -> <IMMED>
  forth:read_find [ " Word name required" panic ] ;unless
  forth:code
  forth:mode [
    LIT, , COMPILE: 2nd!
  ] [
    2nd!
  ] if
;
