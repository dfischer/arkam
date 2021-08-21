TEMPORARY
    LEXI [sys] REFER [core] EDIT
    lexicon: [multi]
    [multi] dup ALSO EDIT

    lexicon: [multi:private]
    [multi:private] dup ALSO EDIT



    # ----- Task -----

    0 var> latest
    0 var> current

    STRUCT Task
        cell: &next
        cell: &prev
        cell: &active
        cell: &sp
        cell: &rp
        cell: &ds_cells
        cell: &rs_cells
        cell: &ds_start
        cell: &rs_start
    END

    : active?   ( task -- ? ) &active @ ;
    : active!   ( task -- ) yes swap &active ! ;
    : inactive! ( task -- ) no swap &active ! ;

    : insert ( task -- )
        dup latest over &next ! latest!
        0 swap &prev !
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
        dup inactive!
        0 over &sp !
        tuck &ds_cells !
        tuck &rs_cells !
        dup allot_ds
        dup allot_rs
        dup init_sp
        tuck init_rp
    ;



    # ----- Setup root task -----
    
    [multi] EDIT
    Task allot as: root_task
    0           root_task &next !
    0           root_task &prev !
    0           root_task &sp !
    0           root_task &rp !
    sys:ds      root_task &ds_start !
    sys:rs      root_task &rs_start !
    sys:ds_size root_task &ds_cells !
    sys:rs_size root_task &rs_cells !
    root_task dup insert current!
    root_task active!


    # ----- Switch -----

    [multi] EDIT

    : awake ( task -- )
        dup active? [ drop ] ;when
        dup active! insert
    ;

    : sleep ( task -- )
        dup active? [ drop ] ;unless
        dup &prev @ ?dup [ ( task prev )
            over &next @ swap &next ! ( keep next )
        ] when
        drop
    ;

    : PAUSE ( -- )
        # save state
        rp current &rp !
        sp current &sp !
        # next task ( round robin )
        current &next @ ?dup [ current! ] [ latest current! ] if
        # restore state
        current [ &sp @ ] [ &ds_start @ ] [ &ds_cells @ ] triq sys:dstack!
        current [ &rp @ ] [ &rs_start @ ] [ &rs_cells @ ] triq sys:rstack!
    ;

    : SLEEP current sleep PAUSE ;



    # ----- Utils -----

    # defaults
    32 var> task:ds_cells
    32 var> task:rs_cells

    : spawn ( xt -- task )
        task:rs_cells task:ds_cells task:new dup awake
    ;

    : task: ( xt -- task ) spawn var> ;


    # ===== Test =====

    " PAUSE" [
        .." root task before ... " PAUSE ." after" PAUSE
    ok ] CHECK

    [ [
        3 [ ? ." I am A" PAUSE ] for
        SLEEP
        GO
      ] while
    ] task: task_a

    [ [
        5 [ ? ." I am B" PAUSE ] for
        SLEEP
        GO
      ] while
    ] task: task_b


    " new_task" [
        PAUSE
        10 [
            ? ." I am ROOT" PAUSE
            2 mod [ task_a ] [ task_b ] if awake PAUSE
        ] for
    ok ] CHECK

END
