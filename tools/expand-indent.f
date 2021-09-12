# expand indent 2 to 4

LEXI [file] REFER [core] EDIT

: usage
    "Usage: expandtab SRC" panic
;

: 0usage IF RET THEN usage ;


var: out
var: srcdata

0 out!

: out! ( fname )
    "w" file:open! out!
    [ out file:putc ] -> putc
;

: load ( fname -- ) loadfile srcdata! ;

: parse-opt
    opt:read! 0usage s:put load
    opt:read! [ out! ] when
;



var: size
var: data
var: newline

: expand-all
    srcdata filesize size!
    srcdata filedata data!
    yes newline!
    size [ data + b@
        10 [ 10 putc yes newline! ] ;case
        newline [ putc ] ;unless
        32 [ space space ] ;case
        putc no newline!
    ] for
;


: main
    parse-opt
    expand-all
;

main
