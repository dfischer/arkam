: ." <IMMED>
  forth:mode [ here ] unless
  POSTPONE: "
  forth:mode [ COMPILE: prn ] [ prn here! ] if
;

