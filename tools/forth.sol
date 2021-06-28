: forth
  const: run_mode     0
  const: compile_mode 1
  val: mode
  val: repl?
  : run_mode!     run_mode     mode! ;
  : compile_mode! compile_mode mode! ;
  : unknown_mode ( mode -- ) ? " : Unknown mode" panic ;

  ( ----- handler ----- )
  : handle_normal ( xt mode -- ... )
    compile_mode [ ,  ] ;CASE
    run_mode     [ >r ] ;CASE
    unknown_mode
  ;
  : handle_immed ( xt mode -- ... ) drop >r ;
  : handle_prim ( xt mode -- )
    # xt-> | prim code
    #      | quot
    compile_mode [ @ ,            ] ;CASE
    run_mode     [ 1 cells + @ >r ] ;CASE
    unknown_mode
  ;

  ( ----- dictionary ----- )
  : dict
    # Structure
    #   | name ...
    #   | (aligned)
    #   |-----
    #   | next
    #   | name addr
    #   | flags
    #   | handler
    #   | xt (code addr)
    #   |-----
    #   | code...
    const: size         5
    const: flag_show 0x01
    val: latest
    : bytes size cells ;
    ( ----- accessors ----- )
    : next     @        ; # h -- h
    : next!    !        ; # a h --
    : name     1 field  ;
    : name!    1 field! ;
    : flags    2 field  ;
    : flags!   2 field! ;
    : handler  3 field  ;
    : handler! 3 field! ;
    : xt       4 field  ;
    : xt!      4 field! ;
    : show!   ( h -- ) dup flags flag_show bit-or  swap flags! ;
    : hide!   ( h -- ) dup flags flag_show bit-xor swap flags! ;
    : hidden? ( h -- ) flags flag_show bit-and not ;
    ( ----- util ----- )
    : here+! ( n -- ) here + align here! ; # aligned
    ( ----- operation ----- )
    : create ( name -- )
      val: header
      : put_name ( str -- &name ) dup s:len 1 + allot here:align! &s:copy sip ;
      put_name # -- &name
      bytes allot header!
      header name! # --
      header show!
      latest header next! header latest! # insert link
      &handle_normal header handler!
      here header xt!
    ;
    : find_from ( name header -- header yes | no )
      dup 0 = IF 2drop no RET END
      dup hidden? IF next AGAIN END
      2dup name s= IF swap drop yes RET END
      next AGAIN
    ;
    : find ( name -- header yes | no ) latest find_from ;
  ;
  : words
    : loop dup IF dup dict:name pr space dict:next AGAIN END ;
    dict:latest loop
  ;
  
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
      "invert"  [ bit-not    ] prim
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
  : compile, ( name -- ) dup >r compile_token not IF r> epr " ?" panic END rdrop ;
  : eval ( str -- ... )
    val: buf
    const: max_token 255
    : init max_token 1 + allot buf! ;
    : buf buf [ init buf ] ;INIT ;
    ( input stack )
    val: source
    val: stream
    : take source stream call source! ;
    : in++ take drop ;
    ( parse a token )
    : space? ( c -- yes | c no ) 0 ;EQ 32 ;EQ 10 ;EQ no ;
    : skip_spaces ( -- c )
      [ take
        dup 0 = IF STOP RET END
        space?  IF GO   RET END
        STOP
      ] while
    ;
    ( string )
    const: dquote 34
    const: bslash 92
    const: lparen 40
    const: rparen 41
    const: amp    38
    : escaped ( c -- c )
      0   [ "Unclosed string" panic ] ;CASE
      110 [ 10                      ] ;CASE # n: newline
      ( as is )
    ;
    : parse_str ( c -- yes | c no )
      dup dquote != IF no RET END drop

      mode compile_mode = IF
        "JMP" compile, here 0 , here swap # -- &str &back
      ELSE
        here # -- addr
      END

      [ take
        0      [ "Unclosed string" panic ] ;CASE
        bslash [ take escaped b, GO      ] ;CASE
        dquote [ 0 b, STOP               ] ;CASE
        b, GO
      ] while
      here:align!

      mode compile_mode = IF
        here swap ! # backpatch
        "LIT" compile, , # str
      END
      yes
    ;
    : parse_comment ( c -- c no | yes )
      dup lparen != IF no RET END drop
      [ take
        0      [ "Unclosed comment" panic ] ;CASE
        rparen [ STOP                     ] ;CASE
        drop GO
      ] while yes
    ;
    ( read a token to buf )
    : read_token ( c -- )
      buf swap 0 [ ( buf c n )
        dup max_token >= IF buf epr " ...Too long token" panic END
        >r ( buf c )
        space? IF rdrop 0 swap b! STOP RET END
        over b! inc take r> inc GO
      ] while
    ;
    : read ( -- read? ) # for defining words
      stream not IF no RET END
      skip_spaces dup not IF no RET END
      read_token yes
    ;
    : notfound ( name -- ) "'" epr epr "'" epr " ?" repl? IF eprn ELSE panic END ;
    ( num )
    : parse_num ( -- n yes | no ) buf s>dec ;
    : eval_num ( n -- ) mode
      compile_mode [ "LIT" compile, ,  ] ;CASE
      run_mode     [ ( remain on TOS ) ] ;CASE
      unknown_mode
    ;
    ( reference )
    : parse_amp ( -- parsed? )
      buf b@ amp != IF no RET END
      buf inc dup >r # -- actual
      dict:find not IF r> notfound no RET END rdrop # -- header
      dict:xt
      mode
      compile_mode [ "LIT" compile, ,  yes ] ;CASE
      run_mode     [ ( remain on TOS ) yes ] ;CASE
      unknown_mode
    ;
    ( main )
    : run ( source stream -- )
      stream >r source >r stream! source!
      [ stream not          IF      ng RET END ( no input stream )
        skip_spaces dup not IF drop ng RET END ( -- c , no more chars )
        parse_str           IF      ok RET END
        parse_comment       IF      ok RET END
        read_token
        parse_amp       IF ok RET END
        buf eval_token  IF ok RET END
        parse_num       IF eval_num ok RET END
        buf notfound ng
      ] while
      r> source! r> stream! ( restore ) ;
    : str ( src -- )
      [ ( str -- c str ) dup b@ swap over IF inc END ] run
    ;
    : include ( fname -- )
      # TODO: detect circular deps
      "r" file:open! dup >r
      [ ( id -- c id ) dup file:getc swap ] run
      r> file:close!
    ;
    str
  ;

  ( ----- handler 2 ----- )
  : handle_data ( xt state -- )
    compile_mode [ "LIT" compile, , ] ;CASE
    run_mode     [ ( push xt )                ] ;CASE
    unknown_mode
  ;
  : handle_compile ( xt state -- )
    compile_mode [ >r                             ] ;CASE
    run_mode     [ "Don't call in run mode" panic ] ;CASE
    unknown_mode
  ;

  ( setup core words )
  : corewords
    : core ( name xt -- ) swap dict:create dict:latest dict:xt! ;
    : immed ( name xt -- ) core &handle_immed   dict:latest dict:handler! ;
    : const ( name v -- )  core &handle_data    dict:latest dict:handler! ;
    : comp  ( name xt -- ) core &handle_compile dict:latest dict:handler! ;
    : colon
      eval:read not IF "word name required" panic END
      eval:buf dict:create dict:latest dict:hide! compile_mode! ;
    : semicolon "RET" compile, dict:latest dict:show! run_mode! ;
    : defconst ( v -- )
      eval:read not IF "const name required" panic END
      eval:buf swap const
    ;
    : open_quot ( -- compile: &quot &back mode | run: &quot mode )
      here:align!
      mode
      compile_mode [ "JMP" compile, here 0 , here swap mode compile_mode! ] ;CASE
      run_mode     [ here                              mode compile_mode! ] ;CASE
      unknown_mode
    ; 
    : close_quot ( &quot &back compile_mode | &quot run_mode -- )
      "RET" compile, dup mode! ( restore mode )
      compile_mode [ here swap ! "LIT" compile, ,     ] ;CASE
      run_mode     [ ( remain quotation addr on TOS ) ] ;CASE
      unknown_mode
    ; ( mode &quot &back -- )
    : include ( fname -- ) eval:include ;
    : include_colon eval:read not IF "file name required" panic END eval:buf include ;
    : setup
      "ok" ok const
      "ng" ng const
      "yes" yes const
      "no"  no const
      "true"  true const
      "false" false const
      "GO"   GO const
      "STOP" STOP const
      
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
      "cell" cell const
      "cells"  &cells  core
      "align"  &align  core
      "field"  &field  core
      "field!" &field! core
      "inc!"   &inc!   core
      "dec!"   &dec!   core
      "memcopy" &memcopy core
      ( ----- combinator ----- )
      "call"   &call  core
      "DEFER"  &DEFER core
      "defer"  &defer core
      "if"     &if    core
      "when"   &when  core
      "unless" &unless core
      "dip"    &dip   core
      "sip"    &sip   core
      "biq"    &biq   core
      "bia"    &bia   core
      "bi*"    &bi*   core
      "bibi"   &bibi  core
      "triq"   &triq  core
      "tria"   &tria  core
      "tri*"   &tri*  core
      ( ----- iterator ----- )
      "times" &times core
      "for"   &for   core
      "while" &while core
      ( ----- stdio ----- )
      "stdio:ready?" &stdio:ready? core
      "putc" &putc core
      "getc" &getc core
      "stdio:port"  &stdio:port  core
      "stdio:port!" &stdio:port! core
      "stdout" stdout const
      "stderr" stderr const
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
      "sys:depth"     &sys:info:depth     core
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
      "c:digit?" &c:digit? core
      "c:upper?" &c:upper? core
      "c:lower?" &c:lower? core
      "c>dec"    &c>dec    core
      "s>dec"  &s>dec  core
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
      
      ( ----- forth ----- )
      ":"       &colon      core
      ";"       &semicolon  immed
      "["       &open_quot  immed
      "]"       &close_quot immed
      "const:"  &defconst   core
      "in:take" &eval:take  core
      "eval"    &eval       core
      "bye"     [ 0 HALT ]  core
      "IF"   [ "ZJMP" compile, here 0 , ] comp
      "ELSE" [ "JMP" compile, here 0 , swap here swap ! ] comp
      "END"  [ here swap ! ] comp
      "AGAIN" [ "JMP" compile, dict:latest dict:xt , ] comp
      
      "include"  &include       core
      "include:" &include_colon core
    ;
  ;
  : repl
    val: buf
    const: len 256
    : buf buf [ len allot dup buf! ] ;INIT ;
    : read buf len getline ; ( -- ok? )
    : prompt "|" epr sys:info:depth ? drop "> " epr ;
    yes repl?!
    [ prompt
      read not IF "too long" eprn GO RET END
      buf eval GO
    ] while
  ;
  : setup
    primitives:setup
    corewords:setup
  ;
;

: main
  forth:setup
  forth:repl
;