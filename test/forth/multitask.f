require: lib/multitask.f

LEXI [multi] REFER

var: count

[ [ count + count! ] recv ] task: counter

[ [ drop 0 1 counter SEND ] recv ] task: inc1

[ [ drop 0 1 counter SEND ] recv ] task: inc2


3 [
    0 1 inc1 SEND PAUSE
    0 1 inc2 SEND PAUSE
] times



count ( 3*2 ) 6 = ASSERT" send/recv"
