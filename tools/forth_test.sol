include: "tester.sol"
include: "forth.sol"


: HERE "-----HERE-----" prn ;


: test_dict
  "create" [ "abcd" forth:dict:create yes ] CHECK

  "create/align" [ forth:dict:latest dup align = ] CHECK
  "create/name"  [ forth:dict:latest forth:dict:name "abcd" s= ] CHECK
  "create/xt"    [ forth:dict:latest forth:dict:xt here = ] CHECK

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
;

: main
  0xFF ? drop "( <- allot ? area )" prn
  "setup" [ forth:setup ok ] CHECK
  test_dict
  "ALL TEST PASSED" prn
;