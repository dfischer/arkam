: forth
  : dict
    # Structure
    #   | name ...
    #   | (aligned)
    #   |-----
    #   | next
    #   | name addr
    #   | handler
    #   | xt (code addr)
    #   |-----
    #   | code...
    const: size         4
    const: run_mode     0
    const: compile_mode 1
    val: latest
    : bytes size cells ;
    ( ----- accessors ----- )
    : next     @     ; # h -- h
    : next!    !     ; # a h --
    : name     1 at  ;
    : name!    1 at! ;
    : handler  2 at  ;
    : handler! 2 at! ;
    : xt       3 at  ;
    : xt!      3 at! ;
    ( ----- handler ----- )
    : handle_normal ( xt state -- ... )
      compile_mode [ ,  ] ;CASE
      run_mode     [ >r ] ;CASE
      ? "Unknown mode" panic
    ;
    : handle_immed ( xt state -- ... ) drop >r ;
    : handle_prim ( xt state -- )
      # xt-> | prim code
      #      | quot
      compile_mode [ @ ,            ] ;CASE
      run_mode     [ 1 cells + @ >r ] ;CASE
    ;
    ( ----- util ----- )
    : here+! ( n -- ) here + align here! ; # aligned
    ( ----- operation ----- )
    : create ( name -- )
      val: header
      : put_name ( str -- &name ) dup s:len 1 + allot here:align! &s:copy sip ;
      put_name # -- &name
      bytes allot header!
      header name! # --
      latest header next! header latest! # insert link
      &handle_normal header handler!
      here header xt!
    ;
  ;
  : primitives
    : prim ( n name q -- n )
      swap dict:create >r
      [ inc ] [ 1 << 1 bit-or ] biq # next code
      , r> , # put code and quotation
      &dict:handle_prim dict:latest dict:handler!
    ;
    : prim_comp ( n name -- n )
      [ "Don't call in run-mode" panic ] prim
    ;
    : setup
      1 ( from HALT )
      "HALT" [ HALT ]  prim
      "LIT"            prim_comp
      "RET"  [ rdrop ] prim
      ( stack )
      "dup"  [ dup  ] prim
      "drop" [ drop ] prim
      "swap" [ swap ] prim
      "over" [ over ] prim
      ( arithmetics )
      "+"    [ +    ] prim
      "-"    [ -    ] prim
      "*"    [ *    ] prim
      "/mod" [ /mod ] prim
      ( compare )
      "="  [ =  ] prim
      "!=" [ != ] prim
      ">"  [ >  ] prim
      "<"  [ <  ] prim
      ( TODO )
      drop
    ;
  ;
  : setup
    primitives:setup
  ;
;

: main
  forth:setup
;