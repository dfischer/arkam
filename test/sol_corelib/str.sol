include: "tester.sol"

: test_s=
  "s= same" [ "foo" "foo" s=     ] CHECK
  "s= diff" [ "foo" "bar" s= not ] CHECK
;

: test_s>dec
  "s>dec positive" [ "123"  s>dec IF  123 = ELSE no END ] CHECK
  "s>dec negative" [ "-123" s>dec IF -123 = ELSE no END ] CHECK
  "s>dec ng1" [ ""  s>dec not ] CHECK
  "s>dec ng2" [ "-" s>dec not ] CHECK
  "s>dec ng3" [ "0a" s>dec not ] CHECK
;

: main
  test_s=
  test_s>dec
;