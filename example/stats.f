PRIVATE

    var: all
    var: hidden
    var: public

    var: all-len
    var: hidden-len
    var: public-len

    : count
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
    ;

    : |> space space space space ;

    : desc ( n s ) swap .. pr space ;
    : len ( n -- ) .. " chars" pr ;

PUBLIC
    : stats
        count
        all " words" desc all-len len cr
        |> public " public" desc public-len len cr
        |> hidden " hidden" desc hidden-len len cr
    ;
END

stats
