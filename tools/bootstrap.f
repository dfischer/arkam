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

---EXPOSE---

  ( latest )
  xhere as: adr_xlatest
  0 x,

  : xlatest  adr_xlatest x@ ;
  : xlatest! adr_xlatest x! ;

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

END


( ===== debug ===== )

: xdump ( madr len -- ) [ x>t ] dip dump ;
: xinfo
  "there 0x" pr there ?hex drop cr
  "here  0x" pr xhere ?hex drop cr
  "start 0x" pr addr_start x@ ?hex drop cr
;

( ===== prim ===== )

: prim ( n -- code ) 1 << 1 or ;
: prim, ( n -- ) prim x, ;


"main" xcreate
xhere entrypoint!
2 prim, 42 x, 1 prim,

xinfo
0 64 xdump
save: out/tmp.ark
bye
