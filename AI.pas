{$F+}
//Модуль "ИИ" для искусственного интеллекта
unit AI;

interface
  uses saveState, timer, math,visuals;
  const  
    JUMPSCARE_LENGTH = 120;
  
  //функции искусственного интеллекта монстров
  
  //Монстр Джёрма  
  procedure jermaAI();

implementation
  
  const
    //константы перемещения Джёрмы
    JERMA_DIRECTION_MATRIX: array [0..8] of array [0..8] of integer = (
                              (0, 0, 1, 0, 1, 0, 0, 0, 0),
                              (0, 0, 0, 1, 1, 0, 0, 0, 0),
                              (1, 0, 0, 0, 0, 1, 0, 0, 0),
                              (0, 1, 0, 0, 0, 0, 0, 0, 0),
                              (1, 1, 0, 0, 0, 1, 0, 1, 1),
                              (0, 0, 1, 0, 1, 0, 1, 0, 0),
                              (0, 0, 0, 0, 0, 1, 0, 1, 0),
                              (0, 0, 0, 0, 1, 0, 1, 0, 1),
                              (0, 0, 0, 0, 1, 0, 0, 1, 0));
    JERMA_MIN_OPP_TIME = 1*120;
    JERMA_MAX_OPP_TIME = 6*120;
    JERMA_RETURN_CHANCE = 0.85;
    JERMA_OFFICE_CHANCE = 0.75;

  //проигрыш и скример
  procedure initiateJumpscare(var jumpscare: JumpscareType; neededJumpscare: JumpscareType;
    var jumpscareTimer: integer);
  begin
    if(jumpscare = JUMPSCARE_NONE) then begin
      jumpscare := neededJumpscare;
      jumpscareTimer := addTimer(state.timers,state.timersLength,JUMPSCARE_LENGTH);
    end;
  end;
  
  //функции искусственного интеллекта монстров
  
  //Монстр Джёрма
  function jermaNextTimer(): real;
  begin
    result := getRandomInt(JERMA_MIN_OPP_TIME, JERMA_MAX_OPP_TIME);
  end;
  
  //Перемещение в следующую комнату
  function jermaDirection(recentCamera, activeCamera: Cameras): Cameras;
  begin
    
    var res := -1;
    
    var dangerChance := getRandomFloat(0, 1);
    if(dangerChance < JERMA_OFFICE_CHANCE) then begin
      case(activeCamera) of
        CAMERA_HALL: res := ord(CAMERA_OFFICE_RIGHT);
        CAMERA_CREEPY: res := ord(CAMERA_OFFICE_LEFT);
        CAMERA_CASINO, CAMERA_SPIDER: res := ord(CAMERA_VENT);
      end;
    end;
    
    if(res <> -1) then
      state.timers[state.jerma.timer] += 5 * 120;
    
    while (res = -1) do
    begin
      var randomCamera := getRandomInt(0, 8);
      var available := JERMA_DIRECTION_MATRIX[ord(activeCamera)][randomCamera];
      if(available = 1) then
        if(randomCamera <> ord(recentCamera)) and (activeCamera <> CAMERA_DARK) or 
          (getRandomFloat(0, 1) > JERMA_RETURN_CHANCE) then
          res := randomCamera;
    end;
    
    Result := Cameras(res);
  end;
  
  procedure jermaAI;
  begin
    //удар электричеством
    if(state.timers[state.shockTimer] >= 0) and (state.timers[state.shockTimer] - 1 / frameDelay <= 0) and 
      (state.jerma.camera = state.shock) then
    begin
      state.jerma.recentCamera := CAMERA_SOLAR;
      state.jerma.camera := CAMERA_SOLAR;
      state.timers[state.jerma.timer] := jermaNextTimer();
    end;
    
    if(state.timers[state.shockTimer] >= 0) then
      state.timers[state.jerma.timer] += 1/frameDelay;
    
    //Монстр Джёрма передвигается
    if(state.timers[state.jerma.timer] <= 0) then begin
      if((state.jerma.camera = CAMERA_OFFICE_RIGHT) or (state.jerma.camera = CAMERA_OFFICE_LEFT) or (state.jerma.camera = CAMERA_VENT)) then
      begin
        initiateJumpscare(state.jumpscare, JUMPSCARE_JERMA, state.jumpscareTimer);
        state.timers[state.jerma.timer] := 9999;
      end
      else begin
        var randomLvl := getRandomInt(1, 20);
        state.timers[state.jerma.timer] := jermaNextTimer();
        if(randomLvl <= state.jerma.lvl) then
        begin
          var cameraSave := state.jerma.camera;
          state.jerma.camera := jermaDirection(state.jerma.recentCamera, state.jerma.camera);
          state.jerma.recentCamera := cameraSave;
        end;
      end;
    end;
  end;

end.