: forth
  const: run_mode     0
  const: compile_mode 1
  val: mode
  : run_mode!     run_mode     mode! ;
  : compile_mode! compile_mode mode! ;

  ( ----- dictionary ----- )
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
    val: latest
    : bytes size cells ;
    ( ----- accessors ----- )
    : next     @        ; # h -- h
    : next!    !        ; # a h --
    : name     1 field  ;
    : name!    1 field! ;
    : handler  2 field  ;
    : handler! 2 field! ;
    : xt       3 field  ;
    : xt!      3 field! ;
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
    : find_from ( name header -- header yes | no )
      dup 0 = IF 2drop no RET END
      2dup name s= IF swap drop yes RET END
      next AGAIN
    ;
    : find ( name -- header yes | no ) latest find_from ;
  ;
  
  ( ----- eval ----- )
  : eval_token_from ( name link -- found? )
    dict:find_from not IF no RET END # -- header
    [ dict:xt ] [ dict:handler ] biq mode swap call ok ;
  ( testing from latest )
  : eval_token ( name -- found? ) dict:latest eval_token_from ;
  : eval_token_in ( name mode -- found? )
    mode >r mode! eval_token r> mode! ;
  : run_token     ( name -- found? ) run_mode     eval_token_in ;
  : compile_token ( name -- found? ) compile_mode eval_token_in ;

  ( ----- setup primitives ----- )
  : primitives
    : primcode ( n -- code ) 1 << 1 bit-or ;
    : prim ( n name q -- n )
      swap dict:create >r
      [ inc ] [ primcode ] biq # next code
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
      ( jump )
      "JMP"  prim_comp
      "ZJMP" prim_comp
      ( get/set )
      "@"  [ @  ] prim
      "!"  [ !  ] prim
      "b@" [ b@ ] prim
      "b!" [ b! ] prim
      ( bitwise )
      "and"     [ bit-and    ] prim
      "or"      [ bit-or     ] prim
      "bnot"    [ bit-not    ] prim
      "xor"     [ bit-xor    ] prim
      "lshift"  [ bit-lshift ] prim
      "ashift"  [ bit-ashift ] prim
      ( I/O )
      "io" [ io ] prim
      ( rstack )
      ">r"    prim_comp
      "r>"    prim_comp
      "rdrop" prim_comp
      ( sp/rp )
      "sp"  [ sp  ] prim
      "sp!" [ sp! ] prim
      "rp"  prim_comp
      "rp!" prim_comp
      ( clean )
      drop
    ;
  ;

  ( setup core words )
  : corewords
    : core ( name xt -- ) swap dict:create dict:latest dict:xt! ;
    : setup
      "not" &not core
      ( ----- stack ----- )
      "nip"   &nip core
      "2dup"  &2dup core
      "2drop" &2drop core
      "3drop" &3drop core
      ( ----- compare ----- )
      "<="  &<= core
      ">="  &>= core
      "max" &max core
      "min" &min core
      ( ----- arithmetics ----- )
      "/"   &/   core
      "mod" &mod core
      "neg" &neg core
      "abs" &abs core
      "inc" &inc core
      "dec" &dec core
      ( ----- bit ----- )
      "<<"  &<<  core
      ">>"  &>>  core
      ">>>" &>>> core
      ( ----- memory ----- )
      "cells"  &cells  core
      "align"  &align  core
      "field"  &field  core
      "field!" &field! core
      "inc!"   &inc!   core
      "dec!"   &dec!   core
      "memcopy" &memcopy core
      ( ----- combinator ----- )
      "call"  &call  core
      "DEFER" &DEFER core
      "dip"   &dip   core
      "sip"   &sip   core
      "biq"   &biq   core
      "bia"   &bia   core
      "bi*"   &bi*   core
      "bibi"  &bibi  core
      "triq"  &triq  core
      "tria"  &tria  core
      "tri*"  &tri*  core
      ( ----- iterator ----- )
      "times" &times core
      "for"   &for   core
      ( ----- stdio ----- )
      "stdio:ready?" &stdio:ready? core
      "putc" &putc core
      "getc" &getc core
      "stdio:port"  &stdio:port  core
      "stdio:port!" &stdio:port! core
      "cr"    &cr    core
      "space" &space core
      "pr"  &pr  core
      "prn" &prn core
      "call/port" &call/port core
      ">stdout" &>stdout core
      ">stderr" &>stderr core
      "epr"  &epr  core
      "eprn" &eprn core
      ( ----- system ----- )
      "sys" &sys core
      "sys:size"      &sys:info:size      core
      "sys:ds_size"   &sys:info:ds_size   core
      "sys:ds"        &sys:info:ds        core
      "sys:rs_size"   &sys:info:rs_size   core
      "sys:rs"        &sys:info:rs        core
      "sys:cell_size" &sys:info:cell_size core
      "sys:max_int"   &sys:info:max_int   core
      "sys:min_int"   &sys:info:min_int   core
      ( ----- exception ----- )
      "die"   &die   core
      "panic" &panic core
      ( ----- address validation ----- )
      "valid:dict" &valid:dict core
      "valid:ds"   &valid:ds   core
      "valid:rs"   &valid:rs   core
      ( ----- memory 2 ----- )
      "here"        &here        core
      "here:addr"   &here:addr   core
      "here:align!" &here:align! core
      "here!"       &here!       core
      ","  &,  core
      "b," &b, core
      "allot" &allot core
      ( ----- debug print ----- )
      ">hex" &>hex core
      "?"      &?      core
      "?hex"   &?hex   core
      "?ff"    &?ff    core
      "?stack" &?stack core
      "?here"  &?here  core
      ( ----- stack 2 ----- )
      "pick"  &pick  core
      "rpick" &rpick core
      "i"     &i     core
      "j"     &j     core
      ( ----- return stack ----- )
      "IFRET" &IFRET core
      ";IF"   &;IF   core
      ";CASE" &;CASE core
      ";EQ"   &;EQ   core
      ";INIT" &;INIT core
      "init!" &init! core
      ( ----- string ----- )
      "s="     &s=     core
      "s:copy" &s:copy core
      "s:put"  &s:put  core
      "s:len"  &s:len  core
      ( ----- random by I/O ----- )
      "rand"       &rand       core
      "rand:seed!" &rand:seed! core
      "rand:init"  &rand:init  core
      ( ----- file ----- )
      "file:open"    &file:open    core
      "file:close"   &file:close   core
      "file:read"    &file:read    core
      "file:write"   &file:write   core
      "file:seek"    &file:seek    core
      "file:exists?" &file:exists? core
      "file:open!"   &file:open!   core
      "file:close!"  &file:close!  core
      "file:read!"   &file:read!   core
      "file:write!"  &file:write!  core
    ;
  ;
  : setup
    primitives:setup
    corewords:setup
  ;
;

: main
  forth:setup
;