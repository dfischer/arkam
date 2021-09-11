TEMPORARY

    LEXI [sys] REFER [core] EDIT
    lexicon: [multi]
    [multi] dup ALSO EDIT

    lexicon: [multi:private]
    [multi:private] dup ALSO EDIT



    # ----- Task -----

    0 var> current

    STRUCT: Task
        cell: &next
        cell: &prev
        cell: &active
        cell: &name
        cell: &sp
        cell: &rp
        cell: &ds-cells
        cell: &rs-cells
        cell: &ds-start
        cell: &rs-start
        ( messaging )
        cell: &sender
        cell: &message
        cell: &parcel
    END

    : active?   ( task -- ? ) &active @ ;
    : active!   ( task -- ) yes swap &active ! ;
    : inactive! ( task -- ) no swap &active ! ;

    : name! ( s task -- ) &name ! ;
    : name ( task -- s )
        &name @ ?dup [ " (noname)" ] unless
    ;

    : insert ( task -- )
        ( prev<-task ) current &prev @ over &prev !
        ( prev->task ) dup &prev @ over swap &next !
        ( task->cur  ) current over &next !
        ( task<-cur  ) current &prev !
    ;

    : remove ( task -- )
        dup [ &prev @ ] [ &next @ ] biq ( task prev next )
        ( prev->next ) 2dup swap &next !
        ( prev<-next ) &prev !
        drop
    ;

    : allot-ds ( task -- )
        dup &ds-cells @ cells allot swap &ds-start !
    ;
    
    : allot-rs ( task -- )
        dup &rs-cells @ cells allot swap &rs-start !    
    ;

    : >empty ( cells stack -- adr ) swap 1 - cells + ;

    : init-sp ( task -- )
        dup [ &ds-cells @ ] [ &ds-start @ ] biq >empty swap &sp !
    ;

    : init-rp ( xt task -- )
        swap >r ( task | xt )
        dup [ &rs-cells @ ] [ &rs-start @ ] biq >empty r> ( task rp xt )
        over ! cell - swap &rp !
    ;

    [multi] EDIT
    : task:new ( xt rs-cells ds-cells -- adr )
        Task allot
        0 over &next !
        0 over &prev !
        0 over &name !
        dup inactive!
        0 over &sp !
        tuck &ds-cells !
        tuck &rs-cells !
        dup allot-ds
        dup allot-rs
        dup init-sp
        tuck init-rp
    ;



    # ----- Inspect -----
    
    [multi:private] EDIT
    : label ( task -- ) dup name pr "@" pr .. ;
    : sep space space ;
    : tab sep sep ;
    
    [multi] EDIT
    : ?task ( task -- task )
        >r
        i label cr
        tab "<- " pr i &prev @ label
        sep i &next @ label "->" prn
        r>
    ;

    : ?tasks
        current ?task
        dup [ ( start task ) &next @
          2dup = [ 2drop STOP ] ;when
          ?task GO
        ] while
    ;



    # ----- Setup root task -----
    
    [multi] EDIT
    Task allot as: root-task
    root-task   root-task &next !
    root-task   root-task &prev !
    0           root-task &sp !
    0           root-task &rp !
    sys:ds      root-task &ds-start !
    sys:rs      root-task &rs-start !
    sys:ds-size root-task &ds-cells !
    sys:rs-size root-task &rs-cells !
    0           root-task &sender !
    0           root-task &message !
    0           root-task &parcel !
    root-task current!
    root-task active!
    " root" root-task name!



    # ----- Switch -----

    [multi] EDIT

    : self current ;

    : awake ( task -- )
        dup active? [ drop ] ;when
        dup active! insert
    ;

    : sleep ( task -- )
        dup active? [ drop ] ;unless
        dup inactive! remove
    ;

    : PAUSE ( -- )
        # save state
        rp current &rp !
        sp current &sp !
        # next task ( round robin )
        current &next @ current!
        # restore state
        current [ &sp @ ] [ &ds-start @ ] [ &ds-cells @ ] triq sys:dstack!
        current [ &rp @ ] [ &rs-start @ ] [ &rs-cells @ ] triq sys:rstack!
    ;

    : SLEEP current sleep PAUSE ;

    : activate ( task -- ) awake PAUSE ;
    


    # ----- Messaging -----

    [multi] EDIT

    : sender self &sender @ ;
    : parcel self &parcel @ ;
    : message self &message @ ;

    : SEND ( parcel message task -- )
        ( wait )
        dup awake [ dup &message @ [ PAUSE GO ] [ STOP ] if ] while
        self over &sender !
        tuck &message !
        &parcel !
        PAUSE
    ;

    : RECV ( -- message )
        ( wait )
        message ?dup [
            SLEEP
            [ message ?dup [ STOP ] [ PAUSE GO ] if ] while
        ] unless

        0 self &message !
    ;

    : recv ( q -- )  # q: message --
        >r RECV i call r> AGAIN
    ;



    # ----- Utils -----

    [multi] EDIT

    # defaults
    32 var> task:ds-cells
    32 var> task:rs-cells

    : spawn ( xt -- task )
        task:rs-cells task:ds-cells task:new dup activate
    ;

    TEMPORARY [forth] ALSO
        : task: ( xt -- task )
            spawn dup var>
            forth:latest forth:next forth:name swap name!
        ;

        : mes: ( name: -- )
            0 as: forth:latest [ forth:name ] [ forth:code cell + ] biq !
        ;
    END



END
