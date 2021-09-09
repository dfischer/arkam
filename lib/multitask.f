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
        cell: &ds_cells
        cell: &rs_cells
        cell: &ds_start
        cell: &rs_start
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

    : allot_ds ( task -- )
        dup &ds_cells @ cells allot swap &ds_start !
    ;
    
    : allot_rs ( task -- )
        dup &rs_cells @ cells allot swap &rs_start !    
    ;

    : >empty ( cells stack -- adr ) swap 1 - cells + ;

    : init_sp ( task -- )
        dup [ &ds_cells @ ] [ &ds_start @ ] biq >empty swap &sp !
    ;

    : init_rp ( xt task -- )
        swap >r ( task | xt )
        dup [ &rs_cells @ ] [ &rs_start @ ] biq >empty r> ( task rp xt )
        over ! cell - swap &rp !
    ;

    [multi] EDIT
    : task:new ( xt rs_cells ds_cells -- adr )
        Task allot
        0 over &next !
        0 over &prev !
        0 over &name !
        dup inactive!
        0 over &sp !
        tuck &ds_cells !
        tuck &rs_cells !
        dup allot_ds
        dup allot_rs
        dup init_sp
        tuck init_rp
    ;



    # ----- Inspect -----
    
    [multi:private] EDIT
    : label ( task -- ) dup name pr .." @" .. ;
    : sep space space ;
    : tab sep sep ;
    
    [multi] EDIT
    : ?task ( task -- task )
        >r
        i label cr
        tab .." <- " i &prev @ label
        sep i &next @ label ." ->"
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
    Task allot as: root_task
    root_task   root_task &next !
    root_task   root_task &prev !
    0           root_task &sp !
    0           root_task &rp !
    sys:ds      root_task &ds_start !
    sys:rs      root_task &rs_start !
    sys:ds_size root_task &ds_cells !
    sys:rs_size root_task &rs_cells !
    0           root_task &sender !
    0           root_task &message !
    0           root_task &parcel !
    root_task current!
    root_task active!
    " root" root_task name!



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
        current [ &sp @ ] [ &ds_start @ ] [ &ds_cells @ ] triq sys:dstack!
        current [ &rp @ ] [ &rs_start @ ] [ &rs_cells @ ] triq sys:rstack!
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
    32 var> task:ds_cells
    32 var> task:rs_cells

    : spawn ( xt -- task )
        task:rs_cells task:ds_cells task:new dup activate
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
