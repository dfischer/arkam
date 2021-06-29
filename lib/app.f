: app:query 12 io ;
: app:argc    0 app:query ; # -- n
: app:get_arg 1 app:query ; # addr i len -- ?


: app:get_arg! ( add i len -- )
  app:get_arg IF RET THEN "Can't get arg!" panic
;
