include: "tester.sol"

: test_s=
  "s= same" [ "foo" "foo" s=     ] CHECK
  "s= diff" [ "foo" "bar" s= not ] CHECK
;

: main test_s= ;