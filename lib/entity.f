( ===== Entity Component System ===== )


COVER

    # entities:
    #   | size
    #   | latest created ( index )
    #   | alive flags ... ( count bytes )
    #
    # components:
    #   | &entities
    #   | cells ...

    STRUCT: entities
        cell field: size
        cell field: latest
        0    field: alives
    END

    STRUCT: components
        cell field: es
        0    field: data
    END

    ( --- entity --- )

    COVER
            var: es
            var: esize
            var: elatest
            var: ecur
            var: erest
            : cur>id es alives - ;
    SHOW
            : new ( es -- id yes | no ) es!
                es size @ dup esize! erest!
                es latest @ elatest!
                es alives elatest + ecur!

                [   erest [ no STOP ] ;unless
                        ecur b@ [
                                ecur inc esize mod ecur!
                                erest dec erest! GO
                        ] ;when
                        ecur inc cur>id esize mod es latest !
                        yes ecur b! ecur cur>id yes STOP
                ] while
            ;
    END


    ( --- name buffer --- )
    # " >name" and " name"
    32         as: actual
    actual 1 - as: max
    actual allot
        dup CHAR: > swap b!
        dup 1 +
        as: getter (  " name" )
        as: setter ( " >name" )

    ( --- components --- )
    : get ( id cs -- v ) data swap cells + @ ;
    : set ( v id cs -- ) data swap cells + ! ;

    : cgetter ( cs -- )
        # ( id -- v )
        getter forth:create
        LIT, , JMP, [ forth:mode [ LIT, , COMPILE: get ] [ get ] if ] ,
    ;

    : csetter ( cs -- )
        # ( v id -- )
        setter forth:create
        LIT, , JMP, [ forth:mode [ LIT, , COMPILE: set ] [ set ] if ] ,
    ;

SHOW

: ecs:new-es ( n -- es )
    here swap dup , 0 , allot drop here:align! ;

: entities: ( n name: -- ) ecs:new-es as: ;

: ecs:size ( es -- n ) size @ ;

: entity:new  ( es -- id yes | no ) new ;

: entity:new! ( es -- id ) new [ " Too many entities" panic ] unless ;

: entity:kill ( id es -- ) alives + no swap b! ;

: entity:each ( es q -- )
    # iterate over alive entities
    # q: ( id -- )
    swap [ alives ] [ size @ ] biq ( q alives n )
    [ ( q alives id -- q alives )
        2dup + b@ not IF drop RET THEN ( dead )
        swap >r swap dup >r call r> r>
    ] for 2drop
;

: ecs:new-cs ( es -- cs ) # new components
    here swap dup , size @ cells allot drop ;

: components: ( es name: -- )
    forth:read [ " component name required" panic ] unless
    max s:check [ " too long component name" panic ] unless
    getter s:copy
    ecs:new-cs dup cgetter csetter
;

( ----- shorthands ----- )

: ENTITY: ( n name: -- es q ) ecs:new-es dup as: [ drop ] ;
: COMPONENT: ( es q name: -- es q ) over components: ;


END
