require: lib/multitask.f

LEXI [multi] REFER

var: count
mes: inc
mes: sum

COVER
    var: count
SHOW
    [ [
        inc [ parcel count + count! ] ;case
        sum [ count sum sender SEND ] ;case
    ] recv ] task: counter
END


[ [ drop 1 inc counter SEND ] recv ] task: inc1

[ [ drop 1 inc counter SEND ] recv ] task: inc2


3 [
    0 1 inc1 SEND PAUSE
    0 1 inc2 SEND PAUSE
] times

0 sum counter SEND
RECV sum = ASSERT" receive sum from counter"
parcel ( 3*2 ) 6 = ASSERT" parcel is sum"

