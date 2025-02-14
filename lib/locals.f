( ===== Locals ===== )

TEMPORARY LEXI [forth] REFER [core] EDIT

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
        " ?" forth:create
        COMPILE: fp LIT, offset , JMP, [ - @ ] ,
        forth:latest getp !
        getp cell + getp!
    ;

    : make-setter
        " ?" forth:create
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
        TEMPORARY [local-vars] EDIT [local-vars] ALSO
        max-locals cells dup
        allot getters!
        allot setters!
        getters getp!
        setters setp!
        max-locals [ make ] times
        ( END ) call
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

    : accessor! ( localc -- )
        cells
            [ getters + @ getter! ]
            [ setters + @ setter! ] biq
    ;

    : remove
        getter [local-vars] forth:remove
        setter [local-vars] forth:remove
    ;

    : register
        [local-vars] getter forth:register
        [local-vars] setter forth:register
    ;

    : def-var ( name -- )
        localc accessor! remove
        [ getter forth:name s:copy ]
        [ setter forth:name s:copy ] biq
        setter forth:name "!" s:append!
        register
    ;

    : def-arg ( name -- )
        def-var
        argc   inc argc!
        localc inc localc!
    ;

    : def-local ( name -- )
        def-var
        localc inc localc!
    ;

    : skip-to-close
        [   forth:take
            0       [ "unclosed locals definition" panic ] ;case
            CHAR: } [ STOP ] ;case
            drop GO
        ] while
    ;

    var: old-close

    : close
        localc [ accessor! remove
            getter setter [ forth:name "" swap s:copy ] bia
            register
        ] for-
        old-close >r
        0 localc! 0 argc!
        PREVIOUS
    ;

SHOW

    init

    : { <IMMED> ( close -- close )
        localc [ " Do not define nested locals" panic ] ;when
        [local-vars] ALSO
        old-close! ' close
        0 argc! 0 localc! ' def-arg -> define
        [   forth:read [ "unclosed locals definition" panic ] ;unless
            dup "|"  s= [ drop ' def-local -> define GO ] ;when
            dup "--" s= [ drop skip-to-close STOP ] ;when
            dup "}"  s= [ drop STOP ] ;when
            define GO
        ] while
        ( finish )
        LIT, localc cells , COMPILE: prepare
        argc [ cells setters + @ forth:code , ] for-
    ;

END


END ( TEMPORARY )
