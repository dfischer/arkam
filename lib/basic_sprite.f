require: lib/core.f
require: lib/ppu.f

loadfile: lib/basic.spr as: basic.spr

: basic.spr:size basic.spr filesize sprite:size / ;
: basic.spr:data basic.spr filedata ;

: basic.spr:load
  basic.spr:data basic.spr:size sprite:bulk_load
;
