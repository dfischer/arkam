# Exception handling from https://www.taygeta.com/forth/dpansa9.htm



0 var> exc-handler


: CATCH ( q -- 0 | exc ) <IMMED>
    forth:mode [ "Do not use CATCH in run mode" panic ] ;unless
    [ # r: -- sp prev
      >r sp r> swap >r  ( q | r: sp )
      exc-handler >r    ( q | r: sp prev )
      rp exc-handler!
      call
      ( no exception )
      rdrop rdrop 0
    ] ,
;


: THROW ( n -- )
    ?dup ;0 ( no exception )
    exc-handler rp!
    r> exc-handler!
    r> swap >r sp! r>
;



( --- test --- )

: foo
    "before foo" prn
    "error in foo" THROW
    "after foo" prn
;

: bar
    "before bar" prn
    foo
    "after bar" prn
;

: baz
    "before baz" prn
    bar
    "after baz" prn
;

: main
    [ baz ] CATCH ?dup IF "Error: " pr prn THEN
;

main
