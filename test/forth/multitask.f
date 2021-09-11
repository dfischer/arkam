require: lib/multitask.f

LEXI [multi] REFER

mes: $inc
mes: $sum

COVER
    var: count
SHOW
    [ [
        $inc [ parcel count + count! ] ;case
        $sum [ count $sum sender SEND ] ;case
    ] recv ] task: counter
END


[ [ drop 1 $inc counter SEND ] recv ] task: inc1

[ [ drop 1 $inc counter SEND ] recv ] task: inc2


3 [
    0 $inc inc1 SEND PAUSE
    0 $inc inc2 SEND PAUSE
] times

0 $sum counter SEND
RECV $sum = "receive sum from counter" ASSERT
parcel ( 3*2 ) 6 = "parcel is sum" ASSERT

