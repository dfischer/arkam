include: "tester.sol"
include: "forth.sol"

: test_dict
  "create addr"  [ here >r "abcd" forth:dict:create r> = ] CHECK
  "create align" [ "abcd" forth:dict:create dup align = ] CHECK
;

: main
  test_dict
;