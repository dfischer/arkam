# Exception handling from https://www.taygeta.com/forth/dpansa9.htm



0 var> exc-handler


: CATCH ( q -- 0 | exc )
    forth:mode [ panic" Do not use CATCH in run mode" ] ;unless
    # r: -- sp prev
    >r sp r> swap >r  ( q | r: sp )
    exc-handler >r    ( q | r: sp prev )
    rp exc-handler!
    call
    ( no exception )
    rdrop rdrop 0
;


: THROW ( n -- )
    ?dup ;0 ( no exception )
    exc-handler rp!
    r> exc-handler!
    r> swap >r sp! r>
;



( --- test --- )

: foo
    ." before foo"
    " error in foo" THROW
    ." after foo"
;

: bar
    ." before bar"
    foo
    ." after bar"
;

: baz
    ." before baz"
    bar
    ." after baz"
;

: main
    [ baz ] CATCH ?dup IF " Error:" pr prn THEN
;

main