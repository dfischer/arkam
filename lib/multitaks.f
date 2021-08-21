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

    : new_task ( rs_cells ds_cells -- adr )
        Task allot
        0 over &next !
        0 over &sp !
        tuck &ds_cells !
        tuck &rs_cells !
        dup allot_ds
        dup allot_rs
    ;



    # ----- Setup root task -----
    
    [multi] EDIT
    Task allot as: root_task
    0           root_task &next !
    0           root_task &sp !
    sys:ds      root_task &ds_start !
    sys:rs      root_task &rs_start !
    sys:ds_size root_task &ds_cells !
    sys:rs_size root_task &rs_cells !
    root_task dup insert current!



    # ----- Switch -----

    [multi] EDIT
    : PAUSE ( -- )
        # save state
        rp sp current &sp !
        # next task ( round robin )
        current &next @ ?dup [ current! ] [ latest current! ] if
        # restore state
        current [ &sp @ ] [ &ds_start @ ] [ &ds_cells @ ] triq sys:dstack!
        ( rp ) current [ &rs_start @ ] [ &rs_cells @ ] biq sys:rstack!
    ;

    var: xt
    : activate ( xt task -- )
        insert xt!
        
        # save state
        current IF rp sp current &sp ! THEN
        
        # restore state
        latest current!
        
        # setup data stack
        current [ &ds_start @ ] [ &ds_cells @ ] biq
        2dup cells + cell - pushdown sys:dstack!
        
        # setup return stack
        current [ &rs_start @ ] [ &rs_cells @ ] biq
        2dup cells + cell - ( rs_start rs_cells rp )
        xt over ! cell -
        pushdown sys:rstack!
    ;



    # ===== Test =====

    var: task_a
    var: task_b

    " PAUSE" [
        .." root task before ... " PAUSE ." after" PAUSE
    ok ] CHECK

    " new_task" [
        32 32 new_task task_a!
        32 32 new_task task_b!
        [ ." I am A" PAUSE ." hello A" PAUSE bye ] task_a activate
        [ ." I am B" PAUSE ." hello B" PAUSE bye ] task_b activate
        ." I am ROOT" PAUSE
    ok ] CHECK

END
