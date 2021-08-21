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
        cell: &sp
        cell: &rp
        cell: &ds_cells
        cell: &rs_cells
        cell: &ds_start
        cell: &rs_start
    END

    : insert ( task -- ) latest over &next ! latest! ;

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

    : new_task ( xt rs_cells ds_cells -- adr )
        Task allot
        0 over &next !
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
    0           root_task &sp !
    0           root_task &rp !
    sys:ds      root_task &ds_start !
    sys:rs      root_task &rs_start !
    sys:ds_size root_task &ds_cells !
    sys:rs_size root_task &rs_cells !
    root_task dup insert current!



    # ----- Switch -----

    [multi] EDIT
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



    # ===== Test =====

    " PAUSE" [
        .." root task before ... " PAUSE ." after" PAUSE
    ok ] CHECK

    " new_task" [
        [ [ ." I am A" GO PAUSE ] while ] 32 32 new_task insert
        [ [ ." I am B" GO PAUSE ] while ] 32 32 new_task insert
        10 [ .. ." I am ROOT" PAUSE ] for
    ok ] CHECK

END
