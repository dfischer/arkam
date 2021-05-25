include: "sarkam.sol"
include: "entity.sol"
include: "basic_sprite.sol"
include: "mgui.sol"
include: "fm.sol"



: rbeat
  val: bpm
  const: bpm_min 30
  const: bpm_max 250
  val: fpb ( frame per 16beat, TimerRate * 60 / 4 / BPM )
  val: frame_i
  const: max_ch   8
  const: beat_len 8
  const: max_age  10  ( note len )
  ( ----- sequencer ----- )
  val: beat_i
  val: beat_life
  : set_bpm ( n -- )
    bpm_min max bpm_max min bpm!
    emu:timer_rate_hz 60 * 4 bpm * / fpb!
  ;
  ( ----- channel ----- )
  const: ch_not_playing -1
  val: channels
  val: playing
  val: freqs
  val: lifes
  val: beat_seqs
  : freq  freqs ecs:get ;
  : freq! freqs ecs:set ;
  : life  lifes ecs:get ;
  : life! lifes ecs:set ;
  : beats  ( ch -- a ) beat_seqs ecs:get ;
  : beats! ( a ch -- ) beat_seqs ecs:set ;
  : beat   ( i ch -- b ) beats + b@ ;
  : beat!  ( b i ch -- ) beats + b! ;
  ( ----- play ----- )
  : play val: ch
    ch!
    ch fm:voice!
    ch freq fm:play
    ; # ch --
  : stop fm:voice! fm:stop ; # ch --
  : next_beat beat_i 1 + beat_len mod beat_i! ;
  : play_all
    0 frame_i!
    0 beat_i!
    yes playing!
  ;
  : stop_all
    no playing!
    0 frame_i!
    0 beat_i!
    channels [ stop ] ecs:each
  ;
  ( ----- randomize ----- )
  : rand_ch ( ch -- )
    val: ch
    dup ch! fm:voice!
    8 rand fm:algo!
    440 rand 20 + ch freq!
    ( beats )
    beat_len [ beat_i!
      3 rand IF 0 beat_i ch beat! RET END
      max_age rand 1 + beat_i ch beat!
    ] for
    ( operators )
    4 [ fm:operator!
      10  rand fm:attack!
      10  rand fm:decay!
      30  rand fm:sustain!
      100 rand fm:release!
      18  rand fm:mod_ratio!
      200 rand fm:fb_ratio!
      4   rand fm:wave!
      255 rand fm:ampfreq!
      255 rand fm:fm_level!
    ] for
  ;
  : rand_channels channels [ rand_ch ] ecs:each ;
  ( ----- draw ----- )
  : draw_ch ( ch -- )  val: ch  val: i  val: x  val: y
    ch!
    ch 16 * 8 + y!
    beat_len [ i!
      i 10 * 8 + x!
      i ch beat IF 3 ELSE 1 END ppu:sprite:i!
      x y ppu:sprite:plot
    ] for
  ;
  : draw_pos
    3 ppu:sprite:i!
    beat_i 10 * 8 + 136 ppu:sprite:plot
  ;
  const: bpm_x 200
  const: bpm_y 8
  : draw_bpm
    bpm bpm_x 20 + bpm_y put_num
  ;
  : draw_all
    channels [ draw_ch ] ecs:each
    draw_bpm
    playing IF draw_pos END
  ;
  ( ----- update ----- )
  : trigger_ch ( ch -- ) val: ch
    ch!
    beat_i ch beat IF ch play RET END
    ch stop
  ;
  : shuffle ( frames -- frames )
    beat_i 2 mod IF RET END 2 + ;
  : update
    # called by timer interruption
    playing not IF RET END

    frame_i 0 = IF ( trigger beats )
      channels [ trigger_ch ] ecs:each
    END

    frame_i 1 + dup fpb >= IF drop next_beat 0 END frame_i!
  ;
  ( ----- init ----- )
  : new_components channels ecs:components ;
  : init
    120 set_bpm
    max_ch ecs:entities channels!
    max_ch [ channels ecs:new! drop ] times
    new_components freqs!
    new_components lifes!
    new_components beat_seqs!
    channels [ beat_len allot swap beats! ] ecs:each
    channels [ ch_not_playing swap life! ] ecs:each
    rand_channels
    0 8   148 "play" [ play_all ] text_button:create
    0 58  148 "stop" [ stop_all ] text_button:create
    0 108 148 "random" [ drop rand_channels ] text_button:create
     10 bpm_x      bpm_y 0x1E [ bpm + set_bpm ] sprite_button:create
    -10 bpm_x 10 + bpm_y 0x1F [ bpm + set_bpm ] sprite_button:create
  ;
;



: main_timer
  const: fps 30
  val: draw_frames
  val: draw_i
  : init emu:timer_rate_hz fps / draw_frames! ;
  : draw_all
    ppu:0clear
    mgui:update
    rbeat:draw_all
    ppu:switch!
  ;
  : update
    rbeat:update
    draw_i 1 + dup draw_frames >= IF
      drop draw_all 0
    END draw_i!
    HALT
  ;
;


: main_loop AGAIN ;


: main
  "rand_fm_beat" emu:title!
  yes emu:show_cursor!
  rand:init
  mgui:init
  basic_sprite:load

  rbeat:init
  rbeat:rand_channels

  main_timer:init
  &main_timer:update emu:timer_handler!

  main_loop
;
