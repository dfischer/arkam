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
