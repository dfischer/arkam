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
;

: main
  "setup" [ forth:setup ok ] CHECK
  test_dict
;