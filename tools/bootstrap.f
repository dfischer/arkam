require: lib/core.f


# Naming and Abbrev
# x -- cross, works on target image
# m -- meta, works on metacompiler (this code)


( ===== Image area and There pointer ===== )

: kilo 1000 * ;
256 kilo        as: image_max
image_max allot as: there


( memory layout )

0x04 as: addr_start
0x08 as: addr_here
0x10 as: addr_begin


( relative pointer )

val: xhere

: x>t there + ; # &x -- &there
: t>x there - ; # &there -- &x

: x@  x>t @ ;
: x!  x>t ! ;
: bx@ x>t b@ ;
: bx! x>t b! ;

: xhere! ( xadr -- )
  dup 0             <  IF .. "invalid xhere" panic THEN
  dup image_max - 0 >= IF .. "invalid xhere" panic THEN
  dup xhere!
  addr_here x!
;


: xhere:align! xhere align xhere! ;

: x,  xhere x!  xhere cell + xhere! ;
: bx, xhere bx! xhere inc    xhere! ;

: x0pad 0 bx, xhere:align! ;

: entrypoint! ( xadr -- ) addr_start x! ;

: image_size xhere x>t there - ;

( initialize )
addr_begin xhere!


( ----- save ----- )

MODULE

  val: id

---EXPOSE---

  : save ( fname -- )
    "wb" file:open! id!
    there image_size id file:write!
    id file:close!
  ;

  : save: ( fname: -- )
    in:read [ "out name required" panic ] unless
    save
  ;

END


( ----- string ----- )

: x:sput ( s -- )
  dup s:len inc >r xhere x>t s:copy r> xhere + xhere! xhere:align!
;


( ===== Cross&Meta Dictionary ===== )

# Cross Dictionary
#  | name ...
#  | ( 0alined )
#  | next
#  | &name
#  | flags
#  | handler
#  | xt
#  |-----
#  | code ...

MODULE

  : mhandle_normal ( xxt state -- )
    # called in compiling core.f on target image
    # xxt is xt address on target image
    forth:compile_mode [ x, ] ;CASE
    forth:run_mode     [ x, ] ;CASE
  ;

---EXPOSE---

  ( latest )
  xhere as: adr_xlatest
  0 x,

  : xlatest  adr_xlatest x@ ;
  : xlatest! adr_xlatest x! ;

  STRUCT xheader
    cell: xnext
    cell: xname
    cell: xflags
    cell: xhandler
    cell: xxt
  END

  : xcreate ( name -- )
    # create xdict entry
    xhere:align!
    xhere swap x:sput xhere:align! # -- &name
    xhere xlatest x, xlatest!      # -- &name
    ( &name   ) x,
    ( flags   ) 0 x,
    ( handler ) 0 x,
    ( xt      ) xhere cell + x,
  ;

  : mcreate ( xxt name -- )
    # create meta-entry
    forth:create
    &mhandle_normal forth:latest forth:handler!
    forth:latest forth:xt!
  ;

END


( ===== debug ===== )

MODULE
  16 as: bpl ( bytes per line )
  : space " " epr ;
  : cr "" eprn ;
  : ?addr ( a -- ) t>x dup 8 >> ?ff ?ff space ;
  : line ( addr len q -- ) swap [ 2dup [ b@ ] dip call &inc dip ] times 2drop ;
  : rest ( len q -- ) swap bpl swap - swap times ;
  : ascii? ( c -- ? ) dup 0x20 < IF drop no RET THEN 0x7E <= ;
  : pchar ( c -- ) dup ascii? IF [ putc ] >stderr ELSE drop "." epr THEN ;
  : ?bytes ( addr len -- ) swap over [ ?ff space ] line [ space space space ] rest ;
  : ?ascii ( addr len -- ) [ pchar ] line ;
  : ?line ( addr len -- ) over ?addr 2dup ?bytes ?ascii cr ;
  : loop ( addr len -- ) dup bpl > IF over bpl ?line [ bpl + ] [ bpl - ] bi* AGAIN THEN ?line ;

---EXPOSE---

  : xdump ( xadr len -- )
    [ x>t ] dip loop
  ;

END

: xinfo
  "there 0x" pr there ?hex drop cr
  "here  0x" pr xhere ?hex drop cr
  "start 0x" pr addr_start x@ ?hex drop cr
;

( ===== prim ===== )

: prim ( n -- code ) 1 << 1 or ;
: prim, ( n -- ) prim x, ;

: num_handler ( n mode -- )
  forth:compile_mode [ 2 prim, x, ] ;CASE
  forth:run_mode     [ 2 prim, x, ] ;CASE
;

: amp_handler ( buf mode -- ) drop "TODO amp handler " epr panic ;

( testing )

: meta:start
  &num_handler forth:num_handler!
  &amp_handler forth:amp_handler!
;

: meta:finish
  xinfo
  0 128 xdump
  "out/tmp.ark" save
  bye
;

: HALT <IMMED> 1 prim, ;



: :
  in:read [ "word name required" panic ] unless
  dup xcreate xlatest xxt x@ swap mcreate
;

: ;
  3 prim,
;


meta:start

: foo 42 HALT ;
: main foo ;
&main entrypoint!


meta:finish
