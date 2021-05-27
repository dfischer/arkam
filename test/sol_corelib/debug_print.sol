include: "tester.sol"

: main
  "?    max"   [  2147483647 ?    ] CHECK
  "?hex max"   [  2147483647 ?hex ] CHECK
  "?    min"   [ -2147483648 ?    ] CHECK
  "?hex min"   [ -2147483648 ?hex ] CHECK
  "?    min+1" [ -2147483647 ?    ] CHECK
  "?hex min+1" [ -2147483647 ?hex ] CHECK
;