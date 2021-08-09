CONTEXT current @
LEXI [forth] REFER [core] EDIT

COVER

    var: all
    var: hidden
    var: public

    var: all-len
    var: hidden-len
    var: public-len

    : init 0 all! 0 hidden! 0 public! 0 all-len! 0 hidden-len! 0 public-len! ;

    : count init
        [ ( lexi )
            [   var' all inc!
                dup forth:name s:len dup all-len + all-len! swap ( len word )
                forth:hidden? [
                    hidden-len + hidden-len!
                    var' hidden inc!
                ] [
                    public-len + public-len!
                    var' public inc!
                ] if
            ] forth:each_word
        ] lexi:each
    ;

    : |> space space space space ;

    : desc ( n s ) swap .. pr space ;
    : len ( n -- ) .. " chars" pr ;

SHOW

    : stats
        count
        all " words" desc all-len len cr
        |> public " public" desc public-len len cr
        |> hidden " hidden" desc hidden-len len cr
    ;

END

LEXI REFER ?words cr stats
EDIT ORDER