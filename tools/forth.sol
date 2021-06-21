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
    ( ----- util ----- )
    : here+! ( n -- ) here + align here! ; # aligned
    ( ----- operation ----- )
    : create ( name -- )
      val: header
      : put_name ( str -- &name ) here >r dup s:len here+! i s:copy r> ;
      put_name # -- &name
      bytes allot header!
      latest header next! header latest! # insert link
      header name! # --
      &handle_normal header handler!
      here header xt!
    ;
  ;
;

: main "forth" prn ;