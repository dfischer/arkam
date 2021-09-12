: ppu:query 3 io ;



( ----- palette ----- )

: ppu:palette-color! 0 ppu:query ; ( color i -- )
: ppu:color!         1 ppu:query ; ( i -- )
: ppu:palette!       2 ppu:query ; ( i -- )
: ppu:palette        3 ppu:query ; ( -- i )



( ----- draw ----- )

: ppu:clear!   10 ppu:query ; ( -- )
: ppu:plot     11 ppu:query ; ( x y -- )
: ppu:ploti    12 ppu:query ; ( i -- )
: ppu:switch!  13 ppu:query ; ( -- )
: ppu:trans!   14 ppu:query ; ( addr -- )
: ppu:copy!    15 ppu:query ; ( -- )
: ppu:width    16 ppu:query ; ( -- w )
: ppu:height   17 ppu:query ; ( -- h )



( ----- sprite ----- )

8  as: sprite:width
64 as: sprite:size

: sprite:i!   20 ppu:query ; ( i -- )
: sprite:load 21 ppu:query ; ( addr -- )
: sprite:plot 22 ppu:query ; ( x y -- )

: sprite:bulk-load ( addr bytes -- )
    sprite:size / [ ( addr i -- addr )
        sprite:i!
        [ sprite:size + ] [ sprite:load ] biq
    ] for drop
;

: sprite:load-blob ( addr -- )
    # addr | size
    #      | data...
    [ cell + ] [ @ ] biq sprite:bulk-load
;



( ----- utils ----- )

: ppu:0clear
    0 ppu:palette!
    0 ppu:color!
    ppu:clear!
;

