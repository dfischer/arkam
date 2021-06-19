: forth
  : dict
    : here+! ( n -- ) here + align here! ; # aligned
    : create ( name -- )
      : put_name ( str -- &name ) here >r dup s:len here+! i s:copy r> ;
      put_name # -- &name
    ;
  ;
;

: main "forth" prn ;