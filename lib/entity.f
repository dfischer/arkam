( ===== Entity Component System ===== )

require: lib/core.f


MODULE

  # entities:
  #   | count
  #   | alive flags ... ( count bytes )
  #
  # components:
  #   | &entities
  #   | cells ...

  STRUCT entities
    cell field: size
    0    field: alives
  END

  STRUCT components
    cell field: es
    0    field: data
  END

  ( --- entity --- )

  : new ( es -- id yes | no )
    [ alives dup ] [ size @ ] biq
    [ ( start current n )
      0 [ 2drop no STOP ] ;CASE
      over b@ [ &inc &dec bi* GO ] ;IF
      drop yes over b! swap - yes STOP
    ] while
  ;


  ( --- name buffer --- )
  # ">name" and "name"
  32         as: actual
  actual 1 - as: max
  actual allot
    dup CHAR: > swap b!
    dup 1 +
    as: getter (  "name" )
    as: setter ( ">name" )

  ( --- components --- )
  : get ( id cs -- v ) data swap cells + @ ;
  : set ( v id cs -- ) data swap cells + ! ;

  : handle_get ( cs state -- )
    ( run )    [ ( id cs -- v ) get ]
    ( compile )[ ( xt -- ) LIT, &get , ]
    forth:handle_mode
  ;

  : cgetter ( cs -- )
    # ( id -- v )
    getter forth:create
    forth:latest forth:xt!
    &handle_get forth:latest forth:handler!
  ;

  : handle_set ( cs state -- )
    ( run )    [ ( v id cs -- ) set ]
    ( compile )[ ( cs -- ) LIT, &set , ]
    forth:handle_mode
  ;

  : csetter ( cs -- )
    # ( v id -- )
    setter forth:create
    forth:latest forth:xt!
    &handle_set forth:latest forth:handler!
  ;

---EXPOSE---

: ecs:new_es ( n -- es )
  here swap dup , allot drop here:align! ;

: entities: ( n name: -- ) ecs:new_es as: ;

: ecs:size ( es -- n ) size @ ;

: entity:new  ( es -- id yes | no ) new ;

: entity:new! ( es -- id ) new [ "Too many entities" panic ] unless ;

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

: ecs:new_cs ( es -- cs ) # new components
  here swap dup , size @ cells allot drop ;

: components: ( es name: -- )
  in:read [ "component name required" panic ] unless
  max s:check [ "too long component name" panic ] unless
  getter s:copy
  ecs:new_cs dup cgetter csetter
;

( ----- shorthands ----- )

: ENTITY ( n name: -- es q ) ecs:new_es dup as: [ drop ] ;
: COMPONENT ( es q name: -- es q ) over components: ;


END
