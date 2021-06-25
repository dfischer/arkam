include: "tester.sol"
include: "forth.sol"


: HERE "-----HERE-----" prn ;


: compile ( name -- ) dup >r forth:compile_token not IF r> pr " not found" panic END rdrop ;
: run     ( name -- ) dup >r forth:run_token     not IF r> pr " not found" panic END rdrop ;


: test_dict
  val: xt
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
;


: main
  0xFF ? drop "( <- allot ? area )" prn
  "setup" [ forth:setup ok ] CHECK
  test_dict
  "ALL TEST PASSED" prn
;