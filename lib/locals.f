( ===== Locals ===== )

CONTEXT CURRENT
LEXI [forth] REFER [core] EDIT

# example:
#     123 as: a
#     foo { a -- a } a ;
#     234 foo => 123

COVER

    var: fp  ( frame pointer )

    lexicon: [local-vars]

    ( ----- local accessors ----- )
    # rstack
    #   ret old-fp |fp| arg0 arg1 ... argN | caller
    #
    # getter: fp (N+4) - @
    # setter: fp (N+4) - !

    16 as: max-locals
    var: getters  var: getp
    var: setters  var: setp

    0 var> offset

    : make-getter
        "  ?" forth:create
        COMPILE: fp LIT, offset , JMP, [ - @ ] ,
        forth:latest getp !
        getp cell + getp!
    ;

    : make-setter
        "  ?" forth:create
        COMPILE: fp LIT, offset , JMP, [ - ! ] ,
        forth:latest setp !
        setp cell + setp!
    ;

    : make
        make-getter
        make-setter
        offset cell + offset!
    ;

    : init
        current @ [local-vars] EDIT [local-vars] ALSO
        max-locals cells dup
        allot getters!
        allot setters!
        getters getp!
        setters setp!
        max-locals [ make ] times
        EDIT PREVIOUS
    ;


    ( runtime )

    : prepare ( bytes -- )
        # rstack
        #   before: ret caller
        #    after: ret old-fp | locals | clean caller
        #       fp: (old-fp - cell)
        r> swap fp >r ( caller bytes )
        rp dup fp! swap - rp!
        [ fp rp! r> fp! ] >r >r
    ;


    ( defining locals )

    var: argc
    var: localc
    var: getter
    var: setter

    defer: define

    : def_var ( name -- )
        localc cells
          [ getters + @ getter! ]
          [ setters + @ setter! ] biq
        [ getter forth:name s:copy ]
        [ setter forth:name s:copy ] biq
        setter forth:name " !" s:append!
    ;

    : def_arg ( name -- )
        def_var
        argc   inc argc!
        localc inc localc!
    ;

    : def_local ( name -- )
        def_var
        localc inc localc!
    ;

    : skip_to_close
        [   forth:take
            0       [ " unclosed locals definition" panic ] ;case
            CHAR: } [ STOP ] ;case
            drop GO
        ] while
    ;

    var: old_close

    : close
        localc [
            cells [ setters + @ ] [ getters + @ ] biq
            [ forth:name " " swap s:copy ] bia
        ] for-
        old_close >r
        0 localc! 0 argc!
        PREVIOUS
    ;

SHOW

    init

    : { <IMMED> ( close -- close )
        localc [ " Do not define nested locals" panic ] ;when
        [local-vars] ALSO
        old_close! ' close
        0 argc! 0 localc! ' def_arg -> define
        [   forth:read [ " unclosed locals definition" panic ] ;unless
            dup " |"  s= [ drop ' def_local -> define GO ] ;when
            dup " --" s= [ drop skip_to_close STOP ] ;when
            dup " }"  s= [ drop STOP ] ;when
            define GO
        ] while
        ( finish )
        LIT, localc cells , COMPILE: prepare
        argc [ cells setters + @ forth:code , ] for-
    ;

END

EDIT ORDER