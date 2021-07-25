: PRIM: <IMMED>
    forth:read_find [ die ] ;unless
    forth:code cell + @ prim>code
    forth:mode [ LIT, , ] when
;


( ===== Locals ===== )

PRIVATE

var: fp  ( frame pointer )


( ----- local accessors ----- )

# rstack
#   ret old-fp |fp| arg0 arg1 ... argN | caller
#
# getter: fp (N+4) - @
# setter: fp (N+4) - !

16 as: max-locals
max-locals cells dup
  allot as: getters
  allot as: setters

getters var> getp
setters var> setp
0 var> offset

: make-getter
    " " forth:create
    COMPILE: fp LIT, offset , JMP, [ - @ ] ,
    forth:latest getp !
    getp cell + getp!
;

: make-setter
    " " forth:create
    COMPILE: fp LIT, offset , JMP, [ - ! ] ,
    forth:latest setp !
    setp cell + setp!
;

: make
  make-getter
  make-setter
  offset cell + offset!
;

: make-locals max-locals [ make ] times ;



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
    localc cells getters + @ getter!
    localc cells setters + @ setter!
    dup getter forth:name s:copy
    setter forth:name s:copy
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
        0       [ panic" unclosed locals definition" ] ;case
        CHAR: } [ STOP ] ;case
        drop GO
    ] while
;

PUBLIC

make-locals

: { <IMMED>
    0 argc! 0 localc! ' def_arg -> define
    [   forth:read [ panic" unclosed locals definition" ] ;unless
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


: bar { | x y z -- }
  3 x!
  4 y!
  5 z!
  x .. y .. z .
;


: foo { a b | c -- }
    a b + c!
    a .. b .. c .
;


: main 1 2 foo bar ;
main