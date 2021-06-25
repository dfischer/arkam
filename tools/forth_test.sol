include: "tester.sol"
include: "forth.sol"


: HERE "-----HERE-----" prn ;
: SECTION ( name -- ) "<< " pr pr " >>" prn ;
: DONE " ...done" prn ;


: compile ( name -- ) dup >r forth:compile_token not IF r> pr " not found" panic END rdrop ;
: run     ( name -- ) dup >r forth:run_token     not IF r> pr " not found" panic END rdrop ;


: test_dict
  val: xt
  "test dict" SECTION

  "create" [ "abcd" forth:dict:create yes ] CHECK

  "create/align" [ forth:dict:latest dup align = ] CHECK
  "create/name"  [ forth:dict:latest forth:dict:name "abcd" s= ] CHECK
  "create/xt"    [ forth:dict:latest forth:dict:xt here = ] CHECK

  forth:dict:latest forth:dict:xt xt!

  "create/handler" [
    forth:dict:latest forth:dict:handler
    &forth:dict:handle_normal =
  ] CHECK

  "find" [
    "abcd" forth:dict:find not IF no RET END
    forth:dict:latest =
  ] CHECK

  "find not found" [
    "foo" forth:dict:find IF drop no ELSE yes END
  ] CHECK

  ( ----- Compile codes of abcd ----- )
  "prereq" [ xt here = ] CHECK
  "dup" compile
  "RET" compile

  "run abcd" [ 1 "abcd" run + 2 = ] CHECK

  DONE
;


: test_primitives
  val: there
  val: x ( for get/set )
  : MARK   here there! ;
  : FORGET there here! ;
  : build ( q -- ) FORGET call "RET" compile ;
  : t "tprim" run ;
  "tprim" forth:dict:create ( for testing compiling primitives )
  MARK

  "test primitives" SECTION
  
  ( ----- run mode ----- )
  "run mode" pr

  "dup"  [ 2 "dup" run + 4 = ] CHECK
  "drop" [ ok no "drop" run ] CHECK
  "swap" [ 1 2 "swap" run - 1 = ] CHECK
  "over" [ 1 2 "over" run - + 2 = ] CHECK

  "+" [ 1 2 "+" run 3 = ] CHECK
  "-" [ 2 1 "-" run 1 = ] CHECK
  "*" [ 3 2 "*" run 6 = ] CHECK
  "/mod" [ 3 2 "/mod" run + 2 = ] CHECK

  "="  [ 2 2 "="  run ] CHECK
  "!=" [ 2 1 "!=" run ] CHECK
  ">"  [ 3 2 ">" run ] CHECK
  "<"  [ 2 3 "<" run ] CHECK

  ( get/set )
  ok x!
  "@" [ &x "@" run ] CHECK
  ng x!
  "!" [ ok &x "!" run x ] CHECK
  ok x!
  "b@" [ &x "b@" run ] CHECK
  ng x!
  "b!" [ ok &x "b!" run x ] CHECK

  ( bitwise )
  "and" [ 1 3 "and" run ] CHECK
  "or"  [ 0 1 "or"  run ] CHECK
  "not" [ 0   "not" run ] CHECK
  "xor" [ 0 1 "xor" run ] CHECK
  "lshift" [ 1 1 "lshift" run 2 = ] CHECK
  "ashift" [ -1 -1 "ashift" run -1 = ] CHECK

  DONE

  ( ----- compile mode ----- )
  "compile mode" pr

  [ "LIT" compile 123 , ] build
  "LIT" [ t 123 = ] CHECK

  [ "drop" compile ] build
  "drop" [ ok no t ] CHECK

  [ "swap" compile ] build
  "swap" [ 1 2 t - 1 = ] CHECK

  [ "over" compile ] build
  "over" [ 1 2 t - + 2 = ] CHECK

  [ "+" compile ] build
  "+" [ 1 2 t 3 = ] CHECK

  [ "-" compile ] build
  "-" [ 2 1 t 1 = ] CHECK

  [ "*" compile ] build
  "*" [ 3 2 t 6 = ] CHECK

  [ "/mod" compile ] build
  "/mod" [ 3 2 t + 2 = ] CHECK

  [ "=" compile ] build
  "="  [ 2 2 t ] CHECK

  [ "!=" compile ] build
  "!=" [ 2 1 t ] CHECK

  [ ">" compile ] build
  ">"  [ 3 2 t ] CHECK

  [ "<" compile ] build
  "<"  [ 2 3 t ] CHECK

  ( jmp )
  [ "JMP" compile here 0 ,
    "dup" compile here swap ! ( skip dup )
    "drop" compile
  ] build
  "JMP" [ 1 t ok ] CHECK

  [ "ZJMP" compile here 0 ,
    "dup"  compile here swap ! ( skip dup if tos is 0 )
    "drop" compile
  ] build
  "ZJMP" [ 1 0 t ok ] CHECK

  ( get/set )
  ok x!
  [ "@" compile ] build
  "@" [ &x t ] CHECK

  ng x!
  [ "!" compile ] build
  "!" [ ok &x t x ] CHECK

  ok x!
  [ "b@" compile ] build
  "b@" [ &x t ] CHECK

  ng x!
  [ "b!" compile ] build
  "b!" [ ok &x t x ] CHECK

  ( bitwise )
  [ "and" compile ] build
  "and" [ 1 3 t ] CHECK

  [ "or" compile ] build
  "or"  [ 0 1 t ] CHECK

  [ "xor" compile ] build
  "xor" [ 1 0 t ] CHECK

  [ "lshift" compile ] build
  "lshift" [ 1 1 t 2 = ] CHECK

  [ "ashift" compile ] build
  "ashift" [ -1 -1 t -1 = ] CHECK

  DONE
;


: main
  0xFF ? drop "( <- allot ? area )" prn
  "setup" [ forth:setup ok ] CHECK
  test_dict
  test_primitives
  "ALL TEST PASSED" prn
;