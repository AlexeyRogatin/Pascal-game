unit game;

interface

uses graphWPF, drawing, saveState, input, AI, math, buttons, visuals, saves, timer;

procedure cycle();

implementation

const
  //кол-во камер на карте
  CAMERA_COUNT = 9;
  
  //длительность анимации поднятия планшета
  LAPTOP_ANIMATION_LENGTH = FPS / 12;
  
  //константы для удара электричеством
  SHOCK_DURATION = 120;
  SHOCK_EFFECT = 60;
  SHOCK_RELOAD = 10 * FPS;
  
  //длительность концовки
  ENDING_LENGTH = 3 * FPS;
  FLASH_FREQUENCY = 60;
  
  //для просмотра по сторонам
  INACTIVE_ZONE = W_WIDTH * 0.4;
  TURN_SPEED = 0.14;
  
  WARNING_HOLDING_LENGTH = 120;

var
  //объекты камер на карте
  cameraObjects: array [0..CAMERA_COUNT - 1] of MapCameraObjType;

procedure changeState(var camera: CameraType; var inGameState: InGameStateType; neededState: InGameStateType);
begin
  case (neededState) of
    STATE_OFFICE: 
      
      if(inGameState = STATE_BACK) then
        if(mouse.x > 0) then begin
          var neededX := -W_WIDTH * 2.25;
          camera.x := neededX - (camera.targetX - camera.x);
          camera.targetX := neededX;
        end
        else begin
          var neededX := W_WIDTH * 2.25;
          camera.x := neededX - (camera.targetX - camera.x);
          camera.targetX := neededX;
        end
        else
      begin
        camera.targetX := 0;
        camera.targetY := 0;
      end;
    
    STATE_BACK:
      begin
        if(mouse.x > 0) then
          camera.x := camera.x - 4.5 * W_WIDTH;
        camera.targetX := -W_WIDTH * 2.25;
      end;
    STATE_VENT:
      begin
        camera.targetY := -W_HEIGHT * 2;
        camera.targetX := 0;
      end;
  end;
  inGameState := neededState;
end;

procedure clearState();
begin
  state.timersLength := 4;
  
  state.camera.x := 0;
  state.camera.y := 0;
  state.camera.targetX := 0;
  state.camera.targetY := 0;
  state.inGameState := STATE_OFFICE;
  state.gameState := STATE_GAME;
  
    //начальная камера
  state.currentCamera := ord(CAMERA_SOLAR);
  
    //Начальные параметры монстра Джёрма
  state.jerma.camera := CAMERA_SOLAR;
  state.jerma.recentCamera := CAMERA_DARK;
  state.jerma.timer := addTimer(state.timers, state.timersLength, FPS * getRandomFloat(1, 5));
  state.jerma.lvl := 13;
  state.jumpscare := JUMPSCARE_NONE;
  
  state.tabletAnimationFrames := 0;
  
  state.timers[state.shockReloadTimer]:=0;
  state.gameTimer := addTimer(state.timers, state.timersLength, GAME_LENGTH);
end;

procedure updateMap(mapX,mapY:real);
begin
  drawSprite(state.camera, 'map.png', mapX, mapY, W_HEIGHT * 0.66, W_HEIGHT * 0.66);
  for var cameraIndex := 0 to CAMERA_COUNT - 1 do
  begin
    var mapCamera := cameraObjects[cameraIndex];
    var cameraPosX := mapX + mapCamera.x;
    var cameraPosY := mapY + mapCamera.y;
    
    if(checkButtonZone(cameraPosX, cameraPosY, mapCamera.width, mapCamera.height, mouse.gamePosX, mouse.gamePosY, true) and 
        (mapCamera.cType = CAMERA_TYPE_RECT) or (mapCamera.cType = CAMERA_TYPE_ROUND) and 
        (distanceBetweenPoints(mouse.gamePosX, mouse.gamePosY, cameraPosX, cameraPosY) < mapCamera.width * 0.58)) then
    begin
      mapCamera.color := ARGB(255, 255, 0, 0);
      if(mouse.wentDown) then begin
        makeNoise(4, 8, 100, 300);
        state.currentCamera := cameraIndex;
        state.cameraOffset := 0;
        mouse.isDown := false;
      end;
    end
    else mapCamera.color := ARGB(255, 0, 0, 0);
    
    if(cameraIndex = state.currentCamera) then mapCamera.color := ARGB(255, 0, 255, 0);
    
    case (mapCamera.cType) of
      CAMERA_TYPE_RECT:
        begin
          drawRect(state.camera, cameraPosX, cameraPosY, mapCamera.width, mapCamera.height, mapCamera.color);
          drawRect(state.camera, cameraPosX, cameraPosY , mapCamera.width - 15, mapCamera.height - 15, RGB(255, 255, 255));
        end;
      CAMERA_TYPE_ROUND:
        begin
          drawCircle(state.camera, cameraPosX, cameraPosY , mapCamera.width * 0.5, mapCamera.color);
          drawCircle(state.camera, cameraPosX, cameraPosY , mapCamera.width * 0.5 - 7.5, RGB(255, 255, 255));
        end;
    end;
  end;
end;

procedure updateLaptop(additionalOffset: real);
begin
  var tabletY := (W_HEIGHT + 25) * (1 - state.tabletAnimationFrames / LAPTOP_ANIMATION_LENGTH);
  
  var cameraSrc := 'cams/cam' + (state.currentCamera + 1) + '.png';
  
  var camInGameWidth := W_HEIGHT / ImageHeight('bitmaps/' + cameraSrc) * ImageWidth('bitmaps/' + cameraSrc);
  
  state.cameraOffset := clamp(state.cameraOffset, (-camInGameWidth + W_WIDTH) * 0.5, (camInGameWidth - W_WIDTH) * 0.5);
  
    //прорисовка того, что видно на камере
    //фон              
  drawSprite(state.camera, cameraSrc, state.camera.x - state.cameraOffset, state.camera.y + tabletY, camInGameWidth, W_HEIGHT);
  
    //прорисовка Джёрмы
  if(state.currentCamera = ord(state.jerma.camera)) then 
    drawSprite(state.camera, 'jerma/cam' + (state.currentCamera + 1) + '.png', state.camera.x - state.cameraOffset, state.camera.y + tabletY, camInGameWidth, W_HEIGHT);
  
    //прорисовка карты камер
  var mapX := state.camera.x + W_WIDTH * 0.5 - W_HEIGHT * 0.36;
  var mapY := state.camera.y + W_HEIGHT * 0.16 + tabletY;
  
  updateMap(mapX,mapY + tabletY);
  
  drawStatic(state.camera, state.camera.x, state.camera.y + tabletY);
  
    //анимация поднятия планшета и его прорисовка
  drawSprite(state.camera, 'camera.png', state.camera.x, state.camera.y + tabletY, W_WIDTH, W_HEIGHT);
  
    //движение камеры
  if(mouse.isDown) then
    state.cameraOffset += additionalOffset;
end;

procedure updateMenu();
begin
  state.camera.x := 0;
  state.camera.y := 0;
  
  drawSprite(state.camera, 'menu.jpg', 400, 0, W_HEIGHT / 3 * 4, W_HEIGHT);
  
  var f: file;
  reset(f, 'save.txt');
  
  drawText(state.camera, 0, -400, W_WIDTH - 300, 80, 'One night at Jerma`s', RGB(255, 255, 255), 'True Lies', LeftCenter);
  if(checkPushButton(-600, -250, 300, 50, mouse.x, mouse.y, 'Start game', mouse.isDown, FPS, frameDelay, LeftCenter)) then
    startTransition(FPS, procedure -> begin state.gameState := STATE_BEFORE_NIGHT; rewrite(f); end);
  
  if(f.Size > 0) then begin
    if(checkPushButton(-600, -100, 300, 50, mouse.x, mouse.y, 'Continue', mouse.isDown, FPS, frameDelay, LeftCenter)) then
      startTransition(FPS, procedure -> loadSave());
  end
  else
    drawText(state.camera, -600, -100, 300, 50, 'Continue', ARGB(127, 255, 255, 255), 'True Lies', LeftCenter);
  close(f);
  
  if(checkNormalButton(-600, 50, 300, 50, mouse.x, mouse.y, 'How to play', mouse.isDown, LeftCenter)) then
    startTransition(FPS, procedure -> state.gameState := STATE_HOW_TO_PLAY1);
  
  if(checkPushButton(-600, 350, 300, 50, mouse.x, mouse.y, 'Exit', mouse.isDown, FPS, frameDelay, LeftCenter)) then
    startTransition(FPS * 2, procedure -> window.close());
end;

procedure updateHowToPlay();
begin
  state.camera.x:=0;
  state.camera.y:=0;
  case state.gameState of
    STATE_HOW_TO_PLAY1:
      begin
        drawParagraph(state.camera, 0, -W_HEIGHT * 0.5 + 300, W_WIDTH * 0.75, 60, 3, 'Interact with buttons by holding them');
        drawText(state.camera, -170, 0, 1, 60, '->');
        if(checkPushButton(0, 0, 300, 50, mouse.x, mouse.y, 'Button', mouse.isDown, FPS, frameDelay, center)) then
          startTransition(FPS, procedure -> state.gameState := STATE_HOW_TO_PLAY2);
      end;
    STATE_HOW_TO_PLAY2:
      begin
        drawParagraph(state.camera, 0, -W_HEIGHT * 0.5 + 300, W_WIDTH * 0.75, 60, 3, 'Move the mouse over the "active zone" at the bottom of the screen to interact with it');
        if(checkActiveZone(0, W_HEIGHT * 0.5 - 25, 1400, 50, mouse)) then
          startTransition(FPS, procedure -> state.gameState := STATE_HOW_TO_PLAY3);
        drawSprite(state.camera, 'button.png', state.camera.x, state.camera.y + W_HEIGHT * 0.5 - 25, 1400, 50);
      end;
    STATE_HOW_TO_PLAY3:
      begin
        drawParagraph(state.camera, 0, -W_HEIGHT * 0.5 + 300, W_WIDTH * 0.75, 60, 3, 'Move the mouse over the "active zone" at the top of the screen to interact with it');
        if(checkActiveZone(0, -W_HEIGHT * 0.5 + 25, 1400, 50, mouse)) then
          startTransition(FPS, procedure -> begin state.gameState := STATE_HOW_TO_PLAY4; state.jerma.camera := Cameras(getRandomInt(0,CAMERA_COUNT-1));
            if(state.jerma.camera = CAMERA_SOLAR) then state.jerma.camera:=succ(state.jerma.camera) end);
        drawSprite(state.camera, 'invertedButton.png', state.camera.x, state.camera.y - W_HEIGHT * 0.5 + 25, 1400, 50);
      end;
    STATE_HOW_TO_PLAY4:
      begin
        if(state.currentCamera = ord(state.jerma.camera)) then begin
          drawRect(state.camera,0,0,W_WIDTH,W_HEIGHT,RGB(120,0,0));
          startTransition(FPS,procedure -> begin state.gameState := STATE_HOW_TO_PLAY5; state.timers[state.shockTimer]:=-1; end);
        end;
        drawParagraph(state.camera, 0, -W_HEIGHT * 0.5 + 300, W_WIDTH * 0.75, 60, 3, 'Interact with rooms on the map to find red room');
        updateMap(0,0);
      end;
    STATE_HOW_TO_PLAY5:
      begin
        var shockLvl := clamp(state.timers[state.shockTimer] / SHOCK_EFFECT, 0, 1) * integer(state.timers[state.shockTimer] <= SHOCK_EFFECT) * 255;
        drawParagraph(state.camera, 0, -W_HEIGHT * 0.5 + 150, W_WIDTH * 0.75, 60, 3, 'Click on the dark passages to light them with flash and scare monsters behind them');
        drawRect(state.camera,0,100,1000,600);
        drawSprite(state.camera,'tutorialPass.png',0,100,1000,600);
        drawRect(state.camera,0,100,200,400,ARGB(255-round(shockLvl),0,0,0));
        if(checkButtonZone(0,100,200,400,mouse.x,mouse.y,mouse.wentDown)and (state.timers[state.shockTimer]<0)) then
          state.timers[state.shockTimer] := SHOCK_DURATION;
        if(state.timers[state.shockTimer]>=0) and (state.timers[state.shockTimer]-1/frameDelay<=0) then
          startTransition(FPS,procedure -> begin state.gameState := STATE_HOW_TO_PLAY6; state.timers[state.shockReloadTimer]:=SHOCK_RELOAD/2; end);
      end;
    STATE_HOW_TO_PLAY6:
      begin
        var shockLvl := clamp(state.timers[state.shockTimer] / SHOCK_EFFECT, 0, 1) * integer(state.timers[state.shockTimer] <= SHOCK_EFFECT) * 255;
        drawParagraph(state.camera, 0, -W_HEIGHT * 0.5 + 150, W_WIDTH * 0.75, 60, 3, 'Now shock has a reload. Wait till the meter fills up and try again');
        drawRect(state.camera,0,100,1000,600);
        drawSprite(state.camera,'tutorialPass.png',0,100,1000,600);
        drawRect(state.camera,0,100,200,400,ARGB(255-round(shockLvl),0,0,0));
        if(checkButtonZone(0,100,200,400,mouse.x,mouse.y,mouse.wentDown)and (state.timers[state.shockTimer]<0)and
          (state.timers[state.shockReloadTimer]<0)) then begin
          state.timers[state.shockTimer] := SHOCK_DURATION;
          state.timers[state.shockReloadTimer]:=SHOCK_RELOAD;
        end;
        if(state.timers[state.shockTimer]>=0) and (state.timers[state.shockTimer]-1/frameDelay<=0) then
          startTransition(FPS,procedure -> state.gameState := STATE_HOW_TO_PLAY7);
        var shockReloadLvl := 1 - clamp(state.timers[state.shockReloadTimer] / SHOCK_RELOAD, 0, 1);
        var barHeight := 150 * shockReloadLvl;
        drawSprite(state.camera, 'shockLvl.png', state.camera.x - 450, state.camera.y - 100, 50, 150);
        drawRect(state.camera, state.camera.x - 450, state.camera.y - 100 + (150 - barHeight) * 0.5, 50, 
          barHeight, ARGB(round(55 + 100 * power(shockReloadLvl, 3)), 0, 0, 255));
      end;
    STATE_HOW_TO_PLAY7:
      begin
        drawParagraph(state.camera, -W_WIDTH * 0.2, -W_HEIGHT * 0.5 + 100, W_WIDTH * 0.55, 60, 3, 'Jerma will go through cameras to your room. He moves only through nearby rooms. When he disappears from the cameras, it means that he is behind one of three passages (2 doors and vent). Scare him by applying shock to the passage. He is always behind the passage, which is closer to the room he was recentry seen in. You don`t want him to enter your room.');
        drawText(state.camera,-W_WIDTH * 0.3,W_HEIGHT*0.5 - 100,10,60,'Click to continue');
        drawSprite(state.camera,'jermaTutorial.png',0.25*W_WIDTH,0,W_HEIGHT * 1280/720,W_HEIGHT);
        if(mouse.wentDown) then
          startTransition(FPS, procedure -> state.gameState := STATE_MENU);
      end;
  end;
end;

procedure updateWarning();
begin
  var offsetX := getRandomInt(-10, 10) * btnPushing / WARNING_HOLDING_LENGTH;
  var offsetY := getRandomInt(-10, 10) * btnPushing / WARNING_HOLDING_LENGTH;
  if(mouse.isDown) then
    btnPushing += 1 / frameDelay;
  if(btnPushing >= WARNING_HOLDING_LENGTH) then begin
    startTransition(FPS, procedure -> state.gameState := STATE_MENU);
    offsetX := 0;
    offsetY := 0;
  end;
  drawText(state.camera, offsetX, offsetY - 200, W_WIDTH, 100, 'Warning', RGB(255, 255, 255));
  drawText(state.camera, offsetX, offsetY, W_WIDTH, 50, 'This game has jumpscares', RGB(255, 255, 255));
  drawText(state.camera, offsetX, offsetY + 200, W_WIDTH, 40, 'Hold mouse to continue...', RGB(255, 255, 255));
  drawText(state.camera, -W_WIDTH * 0.5 + 20, W_HEIGHT * 0.5 - 50, 1, 30, 'One night at Jerma`s', RGB(255, 255, 255), 'True lies', leftCenter);
  drawText(state.camera, W_WIDTH * 0.5 - 20, W_HEIGHT * 0.5 - 50, 1, 30, 'Алексей Рогатин 1413', RGB(255, 255, 255), 'Times new roman', rightCenter);
end;

procedure updateBeforeNight();
begin
  drawParagraph(state.camera, 0, -400, W_WIDTH * 0.42, 60, 3,
    'You are a fan of a very famous internet celebrity Jerma, who became famous because of his show "Peep the horror". One night you broke into his house to get his autograph. It turned out that the Horror was a real  l.iving being. After that  Jerma is no longer willing to keep you alive',
    RGB(255, 255, 255), 'True Lies', center);
  drawText(state.camera, 0, W_HEIGHT * 0.5 - 70, 50, 50, 'SURVIVE  TILL  6 AM', RGB(255, 255, 255), 'True Lies', CenterTop);
  if(mouse.wentDown) then
    startTransition(FPS, procedure -> clearState());
end;

procedure updateGameOver();
begin
  drawText(state.camera, 0, 0, 0, 120, 'You died', RGB(240, 0, 0));
  if(mouse.wentDown) then
    startTransition(FPS, procedure -> state.gameState := STATE_MENU);
end;

procedure updateWin();
begin
  state.camera.x := 0;
  state.camera.y := 0;
  if(state.timers[transition.timer] > 0) or (state.timers[transition.timer] < -ENDING_LENGTH)
              or ((abs(floor(state.timers[transition.timer])) mod FLASH_FREQUENCY) <= FLASH_FREQUENCY / 2) then
    drawText(state.camera, 0, 0, 0, 120, '6 AM', RGB(255, 255, 255), 'Impact');
  if(state.timers[transition.timer] < -ENDING_LENGTH) then
    drawText(state.camera, 0, 300, 0, 120, 'Congratulations!', RGB(255, 255, 255), 'Impact');
  
  if(mouse.wentDown) then
    startTransition(FPS, procedure -> state.gameState := STATE_MENU);
end;

procedure updatePause();
begin
  if(escKey.wentDown) then
    state.gameState := STATE_GAME;
  
  drawText(state.camera, state.camera.x, state.camera.y - 300, 0, 80, 'Pause', RGB(255, 255, 255));
  
  if(checkPushButton(state.camera.x, state.camera.y, 400, 80, mouse.gamePosX, mouse.gamePosY, 'Save & exit',
            mouse.isDown, FPS, frameDelay, center)) then
  begin
    makeSave();
    startTransition(FPS, procedure -> state.gameState := STATE_MENU);
  end;
end;

procedure updateGame();
begin
  //корридоры
  drawSprite(state.camera, 'behindTheDoorsLeft.png', -W_WIDTH * 0.53, 0, 0.18 * W_WIDTH, W_HEIGHT);
  drawSprite(state.camera, 'behindTheDoorsRight.png', W_WIDTH * 0.53, 0, 0.18 * W_WIDTH, W_HEIGHT);
  drawSprite(state.camera, 'behindTheVent.png', 0, -W_HEIGHT * 2.03, W_WIDTH * 0.45, W_WIDTH * 0.45);
  
  //Джёрма в офисе
  if(state.timers[state.shockTimer] > 0) and (state.shock = state.jerma.camera) and 
    (state.timers[state.shockTimer] < SHOCK_EFFECT) then
  begin
    case state.shock of
      CAMERA_OFFICE_RIGHT: drawSprite(state.camera, 'jermaRight.png', W_WIDTH * 0.53, 0, 0.18 * W_WIDTH, W_HEIGHT);
      CAMERA_OFFICE_LEFT: drawSprite(state.camera, 'jermaLeft.png', -W_WIDTH * 0.53, 0, 0.18 * W_WIDTH, W_HEIGHT);
    end;
  end;
  
  if(state.timers[state.shockTimer] > 0) and (state.shock = state.jerma.camera) and 
    (state.timers[state.shockTimer] < SHOCK_EFFECT) and (state.shock = CAMERA_VENT) then
    drawSprite(state.camera, 'jermaVent.png', 0, -W_HEIGHT * 2.03, W_WIDTH * 0.5, W_WIDTH * 0.5);
  
  //эффект электрического разряда        
  var shockLvl := clamp(state.timers[state.shockTimer] / SHOCK_EFFECT, 0, 1) * integer(state.timers[state.shockTimer] <= SHOCK_EFFECT) * 255;
  
  drawRect(state.camera, -W_WIDTH * 0.53, 0, 0.18 * W_WIDTH, W_HEIGHT, 
          ARGB(round(255 - shockLvl * integer(state.shock = CAMERA_OFFICE_LEFT)), 0, 0, 0));
  
  drawRect(state.camera, W_WIDTH * 0.53, 0, 0.18 * W_WIDTH, W_HEIGHT,
          ARGB(round(255 - shockLvl * integer(state.shock = CAMERA_OFFICE_RIGHT)), 0, 0, 0));
  
  drawRect(state.camera, 0, -W_HEIGHT * 2.03, W_WIDTH * 0.45, W_WIDTH * 0.45, 
          ARGB(round(255 - shockLvl * integer(state.shock = CAMERA_VENT)), 0, 0, 0));
  
  //перемещение камеры по сторонам
  var additionalOffset := max((abs(mouse.x) - INACTIVE_ZONE) * 0.04, 0);
  additionalOffset *= 1 / frameDelay;
  if(mouse.x < 0) then additionalOffset *= -1;
  
  drawSprite(state.camera, 'office.png', 0, -W_HEIGHT, W_WIDTH * 1.5, W_HEIGHT * 3);
  
  //анимация опускания планшета
  if(state.inGameState <> STATE_LAPTOP) then begin
    state.tabletAnimationFrames := max(0, state.tabletAnimationFrames - 1 / frameDelay);
  end
  else begin
    state.tabletAnimationFrames := min(LAPTOP_ANIMATION_LENGTH, state.tabletAnimationFrames + 1 / frameDelay);
  end;
  
  if(state.tabletAnimationFrames > 0) then begin
    updateLaptop(additionalOffset);
  end;
  
  case(state.inGameState) of 
    STATE_OFFICE:
      begin
        //перемещение камеры вправо и влево
        var cameraLimit := W_WIDTH * 0.25;
        
        state.camera.targetX += additionalOffset;
        state.camera.targetX := clamp(state.camera.targetX, -cameraLimit, cameraLimit);
        
        //кнопки для офиса
        if(checkActiveZone(0, W_HEIGHT * 0.5 - 25, 1400, 50, mouse)) then begin
          changeState(state.camera, state.inGameState, STATE_LAPTOP);
        end;
        
        if(checkActiveZone(0, -W_HEIGHT * 0.5 + 25, 1400, 50, mouse)) then
          changeState(state.camera, state.inGameState, STATE_VENT);
        
        //нажатие на двери
        if(state.timers[state.shockReloadTimer] < 0) then begin
          if(checkButtonZone(-W_WIDTH * 0.52, 0, 0.36 * W_WIDTH, W_HEIGHT, mouse.gamePosX, mouse.gamePosY, true)) then begin
            if(mouse.wentDown) then begin
              state.shock := CAMERA_OFFICE_LEFT;
              state.timers[state.shockTimer] := SHOCK_DURATION;
              state.timers[state.shockReloadTimer] := SHOCK_RELOAD;
            end;
          end;
          if(checkButtonZone(W_WIDTH * 0.52, 0, 0.36 * W_WIDTH, W_HEIGHT, mouse.gamePosX, mouse.gamePosY, true)) then begin
            if(mouse.wentDown) then begin
              state.timers[state.shockTimer] := SHOCK_DURATION;
              state.shock := CAMERA_OFFICE_RIGHT;
              state.timers[state.shockReloadTimer] := SHOCK_RELOAD;
            end;
          end;
        end;
        
        drawSprite(state.camera, 'invertedButton.png', state.camera.x, state.camera.y - W_HEIGHT * 0.5 + 25, 1400, 50);
        drawSprite(state.camera, 'button.png', state.camera.x, state.camera.y + W_HEIGHT * 0.5 - 25, 1400, 50);
      end;
    STATE_VENT:
      begin
        if(checkActiveZone(0, W_HEIGHT * 0.5 - 25, 1400, 50, mouse)) then
          changeState(state.camera, state.inGameState, STATE_OFFICE);
        
                //нажатие на вентиляцию
        if(state.timers[state.shockReloadTimer] < 0) then begin
          if(checkButtonZone(0, -W_HEIGHT * 2.03, W_WIDTH * 0.45, W_WIDTH * 0.45, mouse.gamePosX, mouse.gamePosY, true)) then begin
            if(mouse.wentDown) then begin
              state.timers[state.shockTimer] := SHOCK_DURATION;
              state.shock := CAMERA_VENT;
              state.timers[state.shockReloadTimer] := SHOCK_RELOAD;
            end;
          end;
        end;
        
        drawSprite(state.camera, 'button.png', state.camera.x, state.camera.y + W_HEIGHT * 0.5 - 25, 1400, 50);
        
      end;
    
    STATE_BACK:
      begin
        drawSprite(state.camera, 'rightButton.png', state.camera.x + W_WIDTH * 0.5 - 25, state.camera.y, 50, 500);
        drawSprite(state.camera, 'leftButton.png', state.camera.x - (W_WIDTH * 0.5 - 25), state.camera.y, 50, 500);
        
        if(checkActiveZone(W_WIDTH * 0.5 - 25, 0, 50, 500, mouse) or 
                checkActiveZone(-W_WIDTH * 0.5 + 25, 0, 50, 500, mouse)) then
          changeState(state.camera, state.inGameState, STATE_OFFICE);
        
      end;
    STATE_LAPTOP:
      begin
        //кнопка возврата для планшета
        if(checkActiveZone(0, W_HEIGHT * 0.5 - 25, 1400, 50, mouse)) then begin
          state.inGameState := STATE_OFFICE;
        end;
        
        drawSprite(state.camera, 'button.png', state.camera.x, state.camera.y + W_HEIGHT * 0.5 - 25, 1400, 50);
      end;
  
  end;
  
  if(escKey.wentDown) then
    state.gameState := STATE_PAUSE;
  
  if(state.timers[state.gameTimer] < 0) then
    startTransition(120, procedure -> state.gameState := STATE_WIN);
  
        //реализация поведения монстра Джёрма
  jermaAI();
  
        //скример и окончание игры
  if(state.jumpscare <> JUMPSCARE_NONE) and (state.timers[state.gameTimer] > 0) then begin
    changeState(state.camera, state.inGameState, STATE_OFFICE);
    state.camera.x := state.camera.targetX;
    state.camera.y := state.camera.targetY;
    state.tabletAnimationFrames := 0;
    
    if(state.timers[state.jumpscareTimer] <= 0) then begin
      var f: file;
      reset(f, 'save.txt');
      rewrite(f);
      close(f);
      state.gameState := STATE_GAME_OVER;
    end
    else
      drawSprite(state.camera, 'jermaScreamer/' + (20 - round(state.timers[state.jumpscareTimer] / JUMPSCARE_LENGTH * 19)) + '.jpg',
      state.camera.x, state.camera.y, W_WIDTH, W_HEIGHT);
  end;    
  
        //отображение полосы заряда шока
  var shockReloadLvl := 1 - clamp(state.timers[state.shockReloadTimer] / SHOCK_RELOAD, 0, 1);
  var barHeight := 150 * shockReloadLvl;
  drawSprite(state.camera, 'shockLvl.png', state.camera.x - W_WIDTH * 0.5 + 100, state.camera.y - W_HEIGHT * 0.5 + 150, 50, 150);
  drawRect(state.camera, state.camera.x - W_WIDTH * 0.5 + 100, state.camera.y - W_HEIGHT * 0.5 + 150 + (150 - barHeight) * 0.5, 50, barHeight, ARGB(round(55 + 100 * power(shockReloadLvl, 3)), 0, 0, 255));
  
        //отображение времени
  var time := (GAME_LENGTH - state.timers[state.gameTimer]) / GAME_LENGTH * 6;
  var hours := floor(time);
  var minutes := '' + floor((time - hours) * 60);
  if(floor((time - hours) * 60) < 10) then
    minutes := '0' + minutes;
  
  drawText(state.camera, state.camera.x + W_WIDTH * 0.5 - 150, state.camera.y - W_HEIGHT * 0.5 + 100, 0, 70, hours + ':' + minutes, RGB(10, 10, 255), 'Impact', center);
end;

procedure cycle;
begin
  window.CenterOnScreen();
  
  window.Clear(RGB(0, 0, 0));
  
  //нахождение задержки с прошлого кадра
  recentFrame := getTime() - recentFrame;
  recentFrame := max(0, recentFrame);
  frameDelay := recentFrame / (1000 / FPS) / 2;
  recentFrame := getTime(); 
  
  //нахождение координат мышки в мире
  mouse.gamePosX := mouse.x + state.camera.x;
  mouse.gamePosY := mouse.y + state.camera.y;
  
  if(not mouse.isDown) then
    btnPushing := 0;
  
  //выбор в зависимости от состояния игры
  case (state.gameState) of
    STATE_WARNING: updateWarning();
    STATE_MENU: updateMenu(); 
    STATE_HOW_TO_PLAY1, STATE_HOW_TO_PLAY2, STATE_HOW_TO_PLAY3, 
      STATE_HOW_TO_PLAY4,STATE_HOW_TO_PLAY5,STATE_HOW_TO_PLAY6,STATE_HOW_TO_PLAY7: updateHowToPlay();
    STATE_BEFORE_NIGHT: updateBeforeNight();
    STATE_GAME_OVER: updateGameOver();
    STATE_PAUSE: updatePause();
    STATE_WIN: updateWin();
    STATE_GAME: updateGame(); 
  end;
  
  if(state.gameState <> STATE_GAME) and (state.gameState <> STATE_WIN) then
  begin
    drawStatic(state.camera, state.camera.x, state.camera.y);
    if(state.timers[state.noise.timer] <= 0) and (getRandomFloat(0, 1) > 0.99) then
      makeNoise(2, 8, 50, 150);
  end;
  
  //очистка ввода
  clearInput();
  
  //сохранение прошлых значений координат мышки
  mouse.recentPosX := mouse.x;
  mouse.recentPosY := mouse.y;
  
  if(state.gameState <> STATE_PAUSE) then
  begin
    updateTimers(state.timers, frameDelay, state.timersLength);
      //перемещение камеры
    state.camera.x += (state.camera.targetX - state.camera.x) * CAMERA_SPEED * frameDelay;
    state.camera.y += (state.camera.targetY - state.camera.y) * CAMERA_SPEED * frameDelay;
  end
  else
    updateTimers(state.timers, frameDelay, 2);
  
  updateTransition();
end;

begin
  
  //подготовка камер к работе
  //основные свойства камер на карте камер
  for var i := 0 to CAMERA_COUNT - 1 do
  begin
    cameraObjects[i].cType := CAMERA_TYPE_RECT;
    cameraObjects[i].width := 120;
    cameraObjects[i].height := 90;
  end;
  cameraObjects[ord(CAMERA_SOLAR)].cType := CAMERA_TYPE_ROUND;
  //пространсвенные свойства для каждой камеры
  cameraObjects[ord(CAMERA_SOLAR)].width := 105;
  
  cameraObjects[ord(CAMERA_HALL)].x := 75;
  cameraObjects[ord(CAMERA_HALL)].y := 150;
  cameraObjects[ord(CAMERA_HALL)].width := 60;
  cameraObjects[ord(CAMERA_HALL)].height := 180;
  
  cameraObjects[ord(CAMERA_CREEPY)].x := -75;
  cameraObjects[ord(CAMERA_CREEPY)].y := 150;
  cameraObjects[ord(CAMERA_CREEPY)].width := 60;
  cameraObjects[ord(CAMERA_CREEPY)].height := 180;
  
  cameraObjects[ord(CAMERA_DARK)].x := -165;
  cameraObjects[ord(CAMERA_DARK)].y := 150;
  cameraObjects[ord(CAMERA_DARK)].width := 60;
  cameraObjects[ord(CAMERA_DARK)].height := 60;
  
  cameraObjects[ord(CAMERA_RING)].x := 0;
  cameraObjects[ord(CAMERA_RING)].y := -150;
  
  cameraObjects[ord(CAMERA_CASINO)].x := -150;
  cameraObjects[ord(CAMERA_CASINO)].y := -105;
  
  cameraObjects[ord(CAMERA_SPIDER)].x := 210;
  cameraObjects[ord(CAMERA_SPIDER)].y := -150;
  
  cameraObjects[ord(CAMERA_CAGE)].x := 210;
  cameraObjects[ord(CAMERA_CAGE)].y := 0;
  
  cameraObjects[ord(CAMERA_BATH)].x := 210;
  cameraObjects[ord(CAMERA_BATH)].y := 150;

end.