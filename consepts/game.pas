program Game;

//бибилиотека прорисовки
uses GraphWpf, Sounds;

const
  CAMERA_COUNT = 9;
  
  //эталонные величины
  W_WIDTH = 1920;
  W_HEIGHT = 1080;
  FPS = 120;
  
  //матрица смежных комнат для перемещения монстров
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
  
  JERMA_MIN_OPP_TIME = 3;
  JERMA_MAX_OPP_TIME = 6;
  JERMA_RETURN_CHANCE = 0.85;
  JERMA_OFFICE_CHANCE = 0.75;
  
  CAMERA_SPEED = 0.08;
  
  LAPTOP_ANIMATION_LENGTH = FPS / 12;
  
  JUMPSCARE_LENGTH = FPS;
  
  SHOCK_DURATION = 120;
  SHOCK_EFFECT = 60;
  SHOCK_RELOAD = 10 * FPS;
  
  TRANSITION_DURATION = FPS;
  
  GAME_LENGTH = FPS * 60 * 6;
  
  DEAFAULT_FONT = 'True Lies';

type
  //тип вектор
  V2 = record
    x: real;
    y: real;
    
    static function operator+(a, b: V2): V2;
    begin
      Result.x := a.x + b.x;
      Result.y := a.y + b.y;
    end;
    
    static procedure operator+=(var a: V2; b: V2);
    begin
      a.x += b.x;
      a.y += b.y;
    end;
    
    static function operator-(a, b: V2): V2;
    begin
      Result.x := a.x - b.x;
      Result.y := a.y - b.y;
    end;
    
    static procedure operator-=(var a: V2; b: V2);
    begin
      a.x -= b.x;
      a.y -= b.y;
    end;
    
    static function operator=(a, b: V2): boolean;
    begin
      Result := (a.x = b.x) and (a.y = b.y);
    end;
    
    static function operator*(a: V2; c: real): V2;
    begin
      Result.x := a.x * c;
      Result.y := a.y * c;
    end;
    
    static function operator*(a: V2; b: V2): V2;
    begin
      Result.x := a.x * b.x;
      Result.y := a.y * b.y;
    end;
    
    static procedure operator*=(var a: V2; c: real);
    begin
      a.x *= c;
      a.y *= c;
    end;
    
    static function operator/(a: V2; c: real): V2;
    begin
      Result.x := a.x / c;
      Result.y := a.y / c;
    end;
    
    static procedure operator/=(var a: V2; c: real);
    begin
      a.x /= c;
      a.y /= c;
    end;
    
    constructor Create(x, y: real);
    begin
      Self.x := x;
      Self.y := y;
    end;
  end;
  
  //тип "мышь"
  MouseType = record
    pos: V2;
    gamePos: V2;
    recentPos: V2;
    isDown: boolean;
    wentDown: boolean;
    wentUp: boolean;
  end;
  
  //типы игровых состояний
  GameStateType = (STATE_WARNING, STATE_MENU, STATE_BEFORE_NIGHT, STATE_GAME, STATE_GAME_OVER, STATE_PAUSE);
  InGameStateType = (STATE_OFFICE, STATE_LAPTOP, STATE_BACK, STATE_VENT);
  
  //тип отображения камеры на карте
  MapCameraType = (CAMERA_TYPE_RECT, CAMERA_TYPE_ROUND);
  //порядковый тип для каждой камеры на карте
  Cameras = (CAMERA_HALL, CAMERA_CREEPY, CAMERA_BATH, CAMERA_DARK, CAMERA_SOLAR, CAMERA_CAGE, CAMERA_SPIDER,  CAMERA_RING, 
  CAMERA_CASINO, CAMERA_OFFICE_RIGHT, CAMERA_OFFICE_LEFT, CAMERA_VENT);
  
  //тип отображаемой камеры
  MapCameraObjType = record
    pos: V2;
    size: V2;
    cType: MapCameraType;
    color: Color;
  end;
  
  //тип камеры, относительно которой происходит прорисовка игры
  CameraType = record
    pos: V2;
    target: V2;
  end;
  
  JumpscareType = (JUMPSCARE_NONE, JUMPSCARE_JERMA, JUMPSCARE_SPIDER, JUMPSCARE_SUS, JUMPSCARE_RAT);
  
  StateType = record    
    //таймеры и размер массива таймеров
    timersLength: integer;
    timers: array [0..100] of real;
    
    //состояние программы
    gameState: GameStateType;
    inGameState: InGameStateType;
    
    //смещения рисунков для эффекта поворота вправо и влево
    cameraOffset: real;
    
    //задействованая камера
    currentCamera: integer;
    //камера
    camera: CameraType;
    
    //уровень поднятия планшета
    tabletAnimationFrames: real;
    
    //объект монстра Джёрма
    jerma: record 
      recentCamera: Cameras;
      camera: Cameras;
      timer: integer;
      lvl: integer;
    end;
    
    //переменные для скримера
    jumpscare: jumpscareType;
    jumpscareTimer: integer;
    
    //переменные для отпугивания
    shockTimer: integer;
    shock: Cameras;
    shockReloadTimer: integer;
    
    //время
    gameTimer: integer;
    
    //шум
    noise: record
      posY: real;
      sizeY: real;
      timer: integer;
    end;
  end;

var
  state: StateType;
  
  //звуки
  ambience: System.Media.SoundPlayer;
  
  //переменная длительности прошлого кадра в миллисекундах
  recentFrame: real;
  //относительная задержка по сравнением с эталонным временем кадра
  frameDelay: real;
  
  //переменная работы программы
  running: boolean;
  
  //мышка
  mouse: MouseType;
  
  //таймер для анимаций перехода
  transition: record
    timer: integer;
    duration: real;
    proc: procedure;
  end;
  
  //объекты камер на карте
  cameraObjects: array [0..8] of MapCameraObjType;
  
  //время удерживания кнопки
  btnPushing: real;
  
  //файл сохранения
  saveFile: file;

//длина вектора
function length(v: V2): real;
begin
  Result := sqrt(v.x * v.x + v.y * v.y);
end;

//процедуры событий мышки и нажатий
procedure MouseDown(x, y: real; mb: integer);
begin
  mouse.isDown := true;
  mouse.wentDown := true;
end;

procedure MouseMove(x, y: real; mb: integer);
begin
  mouse.pos := V2.Create(x, y);
  mouse.pos -= V2.Create(window.Width, window.Height) * 0.5;
  mouse.pos.x *= W_WIDTH / window.Width;
  mouse.pos.y *= W_HEIGHT / window.Height;
end;

procedure MouseUp(x, y: real; mb: integer);
begin
  mouse.isDown := false;
  mouse.wentUp := true;
end;

const
  VK_ESC = 13;

procedure KeyDown(k: Key);
begin
  var keyCode := integer(k);
  if(keyCode = VK_ESC) then begin
    if(state.gameState = STATE_PAUSE) then
      state.gameState := STATE_GAME
    else
    if(state.gameState = STATE_GAME) then
      state.gameState := STATE_PAUSE;
  end;
end;

//ничего
procedure nothing();begin end;

//функции выбора случайного числа из диапазона
function getRandomFloat(min, max: real): real;
begin
  Result := random() * (max - min) + min;
end;

function getRandomInt(min, max: integer): integer;
begin
  Result := round(getRandomFloat(min - 0.5, max + 0.49));
end;

//измерение времени в миллисекундах
function getTime(): double;
begin
  Result := System.DateTime.Now.ToFileTime / 10000;
end;

//clamp помещает число в промежуток
function clamp(val, minv, maxv: real): real;
begin
  Result := min(maxv, max(val, minv));
end;

//расстояние между точками с заданными координатами
function distanceBetweenPoints(a, b: V2): real;
begin
  Result := sqrt(sqr(a.x - b.x) + sqr(a.y - b.y));
end;

//функции прорисовки с учётом размеров окна
procedure drawSprite(camera: CameraType; src: string; pos, size: V2);
begin
  pos -= camera.pos - V2.Create(W_WIDTH, W_HEIGHT) * 0.5;
  pos.x := window.Width * 0.5 + (pos.x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  pos.y := window.Height * 0.5 + (pos.y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  if(length(size) = 0) then begin
    var imgSize := ImageSize(src);
    size.x := imgSize[0];
    size.y := imgSize[1];
  end;
  size.x *= window.Width / W_WIDTH;
  size.y *= window.Height / W_HEIGHT;
  drawImage(pos.x - size.x * 0.5, pos.y - size.y * 0.5, size.x, size.y, src);
end;

procedure drawRect(camera: CameraType; pos, size: V2; clr: Color := RGB(255, 255, 255));
begin
  pos -= camera.pos - V2.Create(W_WIDTH, W_HEIGHT) * 0.5;
  pos.x := window.Width * 0.5 + (pos.x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  pos.y := window.Height * 0.5 + (pos.y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  size.x *= window.Width / W_WIDTH;
  size.y *= window.Height / W_HEIGHT;
  fillRectangle(pos.x - size.x * 0.5, pos.y - size.y * 0.5, size.x, size.y, clr);
end;

procedure drawCircle(camera: CameraType; pos: V2; radius: real; clr: Color := RGB(255, 255, 255));
begin
  pos -= camera.pos - V2.Create(W_WIDTH, W_HEIGHT) * 0.5;
  pos.x := window.Width * 0.5 + (pos.x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  pos.y := window.Height * 0.5 + (pos.y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  var radiusX := radius * window.Width / W_WIDTH;
  var radiusY := radius * window.Height / W_HEIGHT;
  fillEllipse(pos.x, pos.y, radiusX, radiusY, clr);
end;

procedure drawText(camera: CameraType; pos, size: V2; text: string; color: GColor := RGB(255, 255, 255); 
  fontStr: string := DEAFAULT_FONT; align: Alignment := center);
begin
  pos -= camera.pos - V2.Create(W_WIDTH, W_HEIGHT) * 0.5;
  pos.x := window.Width * 0.5 + (pos.x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  pos.y := window.Height * 0.5 + (pos.y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  size.x *= window.Width / W_WIDTH;
  size.y *= window.Height / W_HEIGHT;
  Font.Color := color;
  Font.Size := size.y;
  Font.Name := fontStr;
  drawText(pos.x - size.x * 0.5, pos.y - size.y * 0.5, size.x, size.y, text, align);
end;

procedure drawParagraph(camera: CameraType; pos, size: V2; indent: real; text: string; 
  color: GColor := RGB(255, 255, 255); fontStr: string := DEAFAULT_FONT; align: Alignment := center);
begin
  pos -= camera.pos - V2.Create(W_WIDTH, W_HEIGHT) * 0.5;
  pos.x := window.Width * 0.5 + (pos.x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  pos.y := window.Height * 0.5 + (pos.y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  size.x *= window.Width / W_WIDTH;
  size.y *= window.Height / W_HEIGHT;
  var words := text.Split((' '));
  var str := '';
  var line := 0;
  Font.Color := color;
  Font.Size := size.y;
  Font.Name := fontStr;
  for var wordIndex := 0 to length(words) - 1 do
  begin
    var textWidth := TextWidth(str + words[wordIndex]);
    if(textWidth <= size.x) then
      str += words[wordIndex] + ' '
    else begin
      drawText(pos.x - size.x * 0.5, pos.y - size.y * 0.5, size.x, size.y, str, align);
      pos.y += size.y * indent;
      str := words[wordIndex] + ' ';
    end;
  end;
  drawText(pos.x - size.x * 0.5, pos.y - size.y * 0.5, size.x, size.y, str, align);
end;

procedure makeNoise(minTime, maxTime, minVal, maxVal: real);
begin
  state.timers[state.noise.timer] := getRandomFloat(minTime, maxTime);
  state.noise.posY := getRandomFloat(-W_HEIGHT * 0.5, W_HEIGHT * 0.5);
  state.noise.sizeY := getRandomFloat(minVal, maxVal);
end;

procedure updateNoise();
begin
  if(state.timers[state.noise.timer] > 0) then begin
    drawRect(state.camera, state.camera.pos + V2.Create(0, state.noise.posY), V2.Create(W_WIDTH, state.noise.sizeY), RGB(255, 255, 255));
  end;
end;

procedure drawStatic(camera: CameraType; pos: V2);
begin
  var size := V2.Create(W_WIDTH, W_HEIGHT);
  
  //прорисовка помех
  drawSprite(state.camera, 'static/' + getRandomInt(1, 8) + '.png', pos, size);
  
  updateNoise();
end;

//проверка наведения на активную зону
//Активная зона - вид взаимодействия пользователя с программой, при котором пользователь наводит мышью на 
//определённую область экрана, чтобы произошло событие.
function checkActiveZone(pos, size: V2; mouse: MouseType): boolean;
begin
  var res := false;
  var left := pos.x - size.x * 0.5;
  var right := pos.x + size.x * 0.5;
  var top := pos.y - size.y * 0.5;
  var bottom := pos.y + size.y * 0.5;
  if(mouse.pos.x >= left) and (mouse.pos.x <= right) and (mouse.pos.y >= top) and (mouse.pos.y <= bottom) and
    not ((mouse.recentPos.x >= left) and (mouse.recentPos.x <= right) and 
    (mouse.recentPos.y >= top) and (mouse.recentPos.y <= bottom)) then
    res := true;
  
  result := res;
end;

//проверка нажатия на кнопку
function checkButtonZone(pos, size: V2; mousePos: V2; condition: boolean := true): boolean;
begin
  var res := false;
  var left := pos.x - size.x * 0.5;
  var right := pos.x + size.x * 0.5;
  var top := pos.y - size.y * 0.5;
  var bottom := pos.y + size.y * 0.5;
  if(mousePos.x >= left) and (mousePos.x <= right) and (mousePos.y >= top) and (mousePos.y <= bottom) and condition then
    res := true;
  
  result := res;
end;

//проверка нажатия на кнопку меню
function checkNormalButton(pos, size: V2; mousePos: V2; str: string; condition: boolean; align: Alignment): boolean;
begin
  var res := false;
  if(checkButtonZone(pos, size, mousePos, state.timers[transition.timer] <= 0)) then
  begin
    if(getRandomFloat(0, 1) > 0.95) then 
      str[getRandomInt(1, length(str))] := chr(getRandomInt(0, 90));
    if(getRandomFloat(0, 1) > 0.95) then
      pos += V2.Create(getRandomFloat(-5, 5), getRandomFloat(-5, 5));
    if(condition) then
      res := true;
  end;
  
  //  drawRect(camera,pos,size,RGB(0,255,0));
  drawText(state.camera, pos, size, str, RGB(255, 255, 255), DEAFAULT_FONT, align);
  
  result := res;
end;

function checkPushButton(pos, size: V2; mousePos: V2; str: string; condition: boolean; holdingLength: real; frameDelay: real; align: Alignment): boolean;
begin
  var res := false;
  var addPos := V2.Create(0, 0);
  if(checkButtonZone(pos, size, mousePos, state.timers[transition.timer] <= 0)) then
  begin
    addPos := V2.Create(getRandomInt(-10, 10), getRandomInt(-10, 10)) * btnPushing / holdingLength;
    if(condition) then begin
      btnPushing += frameDelay;
      if(btnPushing >= holdingLength) then
        res := true;
    end;
  end;
  
  //  drawRect(camera,pos,size,RGB(0,255,0));
  checkNormalButton(pos + addPos, size, mousePos, str, condition, align);
  
  result := res;
end;

//добавление нового таймера и обновление значения таймеров
function addTimer(time: real): integer;
begin
  result := state.timersLength;
  state.timers[state.timersLength] := time;
  state.timersLength += 1;
end;

procedure updateTimers(frameDelay: real; count: integer);
begin
  for var timerIndex := 0 to count - 1 do
    state.timers[timerIndex] -= frameDelay;
end;

//проигрыш и скример
procedure initiateJumpscare(var jumpscare: JumpscareType; neededJumpscare: JumpscareType; var jumpscareTimer: integer);
begin
  if(jumpscare = JUMPSCARE_NONE) then begin
    jumpscare := neededJumpscare;
    jumpscareTimer := addTimer(JUMPSCARE_LENGTH);
  end;
end;

//функции искусственного интеллекта монстров

//Монстр Джёрма

function jermaNextTimer(): real;
begin
  result := getRandomInt(JERMA_MIN_OPP_TIME, JERMA_MAX_OPP_TIME) * FPS;
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
    state.timers[state.jerma.timer] += 5 * FPS;
  
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

procedure jermaAI();
begin
  //удар электричеством
  if(state.timers[state.shockTimer] >= 0) and (state.timers[state.shockTimer] - frameDelay <= 0) and 
    (state.jerma.camera = state.shock) then
  begin
    state.jerma.recentCamera := CAMERA_SOLAR;
    state.jerma.camera := CAMERA_SOLAR;
    state.timers[state.jerma.timer] := jermaNextTimer();
  end;
  
  if(state.timers[state.shockTimer] >= 0) then
    state.timers[state.jerma.timer] += frameDelay;
  
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

//изменение внутриигрового состояния
procedure changeState(var camera: CameraType; var inGameState: InGameStateType; neededState: InGameStateType);
begin
  case (neededState) of
    STATE_OFFICE: 
      
      if(inGameState = STATE_BACK) then
        if(mouse.pos.x > 0) then begin
          var neededX := -W_WIDTH * 2.25;
          camera.pos.x := neededX - (camera.target.x - camera.pos.x);
          camera.target := V2.Create(neededX, 0);
        end
        else begin
          var neededX := W_WIDTH * 2.25;
          camera.pos.x := neededX - (camera.target.x - camera.pos.x);
          camera.target := V2.Create(neededX, 0);
        end
      else
        camera.target := V2.Create(0, 0);
    
    STATE_BACK:
      begin
        if(mouse.pos.x > 0) then
          camera.pos.x := camera.pos.x - 4.5 * W_WIDTH;
        camera.target := V2.Create(-W_WIDTH * 2.25, 0);
      end;
    STATE_VENT:
    camera.target := V2.Create(0, -W_HEIGHT * 2);
  end;
  inGameState := neededState;
end;

//процедуры плавного перехода
procedure startTransition(duration: real; proc: procedure);
begin
  if(state.timers[transition.timer] > -duration * 0.5)  then begin
    if(state.timers[transition.timer] < 0) then
      state.timers[transition.timer] := -state.timers[transition.timer];
  end
  else
    state.timers[transition.timer] := duration * 0.5;
  transition.duration := duration;
  transition.proc := proc;
end;

procedure updateTransition();
begin
  var transitionLvl := clamp(1 - abs(state.timers[transition.timer]) / (transition.duration * 0.5), 0, 1);
  drawRect(state.camera, state.camera.pos, V2.Create(W_WIDTH, W_HEIGHT), ARGB(round(transitionLvl * 255), 0, 0, 0));
  if(state.timers[transition.timer] >= 0) and (state.timers[transition.timer] - frameDelay <= 0) then
    transition.proc();
end;

//процедура перехода к основой части игры
procedure startGame();
begin  
  state.timersLength := 2;
  
  state.camera.pos := V2.Create(0, 0);
  state.camera.target := V2.Create(0, 0);
  state.inGameState := STATE_OFFICE;
  state.gameState := STATE_GAME;
  
  //начальная камера
  state.currentCamera := ord(CAMERA_SOLAR);
  
  //Начальные параметры монстра Джёрма
  state.jerma.camera := CAMERA_SOLAR;
  state.jerma.recentCamera := CAMERA_DARK;
  state.jerma.timer := addTimer(FPS * getRandomFloat(1, 5));
  state.jerma.lvl := 13;
  
  state.tabletAnimationFrames := 0;
  state.jumpscare := JUMPSCARE_NONE;
  state.shockTimer := addTimer(-1);
  state.shockReloadTimer := addTimer(-1);
  state.gameTimer := addTimer(GAME_LENGTH);
end;

procedure updateLaptop(additionalOffset: real);
begin
  var tabletY := (W_HEIGHT + 25) * (1 - state.tabletAnimationFrames / LAPTOP_ANIMATION_LENGTH);
  var tabletPos := state.camera.pos + V2.Create(0, tabletY);
  
  var cameraSrc := 'cams/cam' + (state.currentCamera + 1) + '.png';
  var cameraSpriteWidth := ImageWidth(cameraSrc);
  var cameraSpriteHeight := ImageHeight(cameraSrc);
  
  var camInGameWidth := W_HEIGHT / cameraSpriteHeight * cameraSpriteWidth;
  
  state.cameraOffset := clamp(state.cameraOffset, (-camInGameWidth + W_WIDTH) * 0.5, (camInGameWidth - W_WIDTH) * 0.5);
  
  //прорисовка того, что видно на камере
  
  //фон              
  drawSprite(state.camera, cameraSrc, tabletPos - V2.Create(state.cameraOffset, 0), V2.Create(camInGameWidth, W_HEIGHT));
  
  //прорисовка Джёрмы
  if(state.currentCamera = ord(state.jerma.camera)) then 
    drawSprite(state.camera, 'jerma.png', tabletPos - V2.Create( state.cameraOffset, 0), V2.Create(W_WIDTH, W_HEIGHT));
  
  //прорисовка карты камер
  var centralPos := V2.Create(W_WIDTH * 0.5 - W_HEIGHT * 0.36, W_HEIGHT * 0.16) + V2.Create(0, tabletY);
  
  drawSprite(state.camera, 'map.png', tabletPos + V2.Create(centralPos.x, centralPos.y), V2.Create(W_HEIGHT * 0.66, W_HEIGHT * 0.66));
  
  for var cameraIndex := 0 to CAMERA_COUNT - 1 do
  begin
    var mapCamera := cameraObjects[cameraIndex];
    var cameraPos := centralPos + mapCamera.pos;
    
    if(checkButtonZone(cameraPos, mapCamera.size, mouse.pos, true) and (mapCamera.cType = CAMERA_TYPE_RECT) or
      (mapCamera.cType = CAMERA_TYPE_ROUND) and 
      (distanceBetweenPoints(mouse.pos, cameraPos) < mapCamera.size.x * 0.58)) then
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
          drawRect(state.camera, tabletPos + cameraPos, mapCamera.size, mapCamera.color);
          drawRect(state.camera, tabletPos + cameraPos, mapCamera.size - V2.Create(15, 15), RGB(255, 255, 255));
        end;
      CAMERA_TYPE_ROUND:
        begin
          drawCircle(state.camera, tabletPos + cameraPos, mapCamera.size.x * 0.5, mapCamera.color);
          drawCircle(state.camera, tabletPos + cameraPos, mapCamera.size.x * 0.5 - 7.5, RGB(255, 255, 255));
        end;
    end;
  end;
  
  drawStatic(state.camera, tabletPos);
  
  //  if(state.tabletAnimationFrames<>LAPTOP_ANIMATION_LENGTH) then
  //    state.timers[state.noise.timer]:=-1;
  
    //анимация поднятия планшета и его прорисовка
  drawSprite(state.camera, 'camera.png', tabletPos, V2.Create(W_WIDTH, W_HEIGHT));
  
  //движение камеры
  if(mouse.isDown) then
    state.cameraOffset += additionalOffset;
end;


//проыедуры работы с файлом сохранения
procedure loadSave();
begin
  close(saveFile);
  reset(saveFile);
  var newState: StateType;
  read(saveFile, newState);
  state := newState;
  state.timers[transition.timer] := -1;
end;

procedure makeSave();
begin
  state.gameState := STATE_GAME;
  rewrite(saveFile);
  write(saveFile, state);
end;

//цикл за один кадр
procedure cycle();
begin
  window.CenterOnScreen();
  
  window.Clear(RGB(0, 0, 0));
  
  //нахождение задержки с прошлого кадра
  recentFrame := getTime() - recentFrame;
  recentFrame := max(0, recentFrame);
  frameDelay := recentFrame / (1000 / FPS) / 2;
  recentFrame := getTime(); 
  
  //нахождение координат мышки в мире
  mouse.gamePos := mouse.pos + state.camera.pos;
  
  //выбор в зависимости от состояния игры
  case (state.gameState) of
    STATE_WARNING:
      begin
        drawText(state.camera, V2.Create(0, -200), V2.Create(W_WIDTH, 100), 'Warning', RGB(255, 255, 255));
        drawText(state.camera, V2.Create(0, 200), V2.Create(W_WIDTH, 50), 'This game has loud noises and jumpscares', RGB(255, 255, 255));
        if(mouse.wentDown) then
          startTransition(FPS, procedure -> state.gameState := STATE_MENU);
      end;
    
    //меню
    STATE_MENU:
      begin
        state.camera.pos := V2.Create(0, 0);
        
        drawText(state.camera, V2.Create(0, -400), V2.Create(W_WIDTH - 300, 80), 'One night at Jerma`s', RGB(255, 255, 255), 'True Lies', LeftCenter);
        if(checkPushButton(V2.Create(-600, -250), V2.Create(300, 50), mouse.pos, 'Start game', mouse.isDown, FPS, frameDelay, LeftCenter)) then
          startTransition(FPS, procedure -> state.gameState := STATE_BEFORE_NIGHT);
        
        if(saveFile.Size > 0) then begin
          if(checkPushButton(V2.Create(-600, -100), V2.Create(300, 50), mouse.pos, 'Continue', mouse.isDown, FPS, frameDelay, LeftCenter)) then
            startTransition(FPS, procedure -> loadSave());
        end
        else
          drawText(state.camera, V2.Create(-600, -100), V2.Create(300, 50), 'Continue', ARGB(127, 255, 255, 255), 'True Lies', LeftCenter);
        
        checkNormalButton(V2.Create(-600, 50), V2.Create(300, 50), mouse.pos, 'Options', mouse.wentDown, LeftCenter);
        
        checkNormalButton(V2.Create(-600, 200), V2.Create(300, 50), mouse.pos, 'Extras', mouse.wentDown, LeftCenter);
        
        if(checkPushButton(V2.Create(-600, 350), V2.Create(300, 50), mouse.pos, 'Exit', mouse.isDown, FPS, frameDelay, LeftCenter)) then
          startTransition(FPS * 2, procedure -> running := false);
      end;
    
    STATE_BEFORE_NIGHT:
      begin
        drawParagraph(state.camera, state.camera.pos + V2.Create(0, -400), V2.Create(W_WIDTH * 0.42, 50), 2,
        'You are a fan of a very famous internet celebrity Jerma, who became famous because of his show "Peep the horror". One night you broke into his house to get his autograph. It turned out that the Horror was a real  l.iving being. After that  Jerma is no longer willing to keep you alive',
        RGB(255, 255, 255), 'True Lies', center);
        if(mouse.wentDown) then
          startTransition(FPS, procedure -> begin startGame(); end);
      end;
    
    //состояние игра
    STATE_GAME:
      begin
        //корридоры
        drawSprite(state.camera, 'behindTheDoorsLeft.png', V2.Create(-W_WIDTH * 0.53, 0), V2.Create(0.18 * W_WIDTH, W_HEIGHT));
        drawSprite(state.camera, 'behindTheDoorsRight.png', V2.Create(W_WIDTH * 0.53, 0), V2.Create(0.18 * W_WIDTH, W_HEIGHT));
        drawSprite(state.camera, 'behindTheVent.png', V2.Create(0, -W_HEIGHT * 2.03), V2.Create(W_WIDTH * 0.45, W_WIDTH * 0.45));
        
        //эффект электрического разряда        
        var shockLvl := clamp(state.timers[state.shockTimer] / SHOCK_EFFECT, 0, 1) * integer(state.timers[state.shockTimer] <= SHOCK_EFFECT) * 255;
        
        drawRect(state.camera, V2.Create(-W_WIDTH * 0.53, 0), V2.Create(0.18 * W_WIDTH, W_HEIGHT), 
        ARGB(round(255 - shockLvl * integer(state.shock = CAMERA_OFFICE_LEFT)), 0, 0, 0));
        
        drawRect(state.camera, V2.Create(W_WIDTH * 0.53, 0), V2.Create(0.18 * W_WIDTH, W_HEIGHT),
        ARGB(round(255 - shockLvl * integer(state.shock = CAMERA_OFFICE_RIGHT)), 0, 0, 0));
        
        drawRect(state.camera, V2.Create(0, -W_HEIGHT * 2.03), V2.Create(W_WIDTH * 0.45, W_WIDTH * 0.45), 
        ARGB(round(255 - shockLvl * integer(state.shock = CAMERA_VENT)), 0, 0, 0));
        
        //перемещение камеры по сторонам
        var additionalOffset := max((abs(mouse.pos.x) - 60) * 0.04, 0);
        additionalOffset *= frameDelay;
        if(mouse.pos.x < 0) then additionalOffset *= -1;
        
        drawSprite(state.camera, 'newOffice.png', V2.Create(0, -W_HEIGHT), V2.Create(W_WIDTH * 11, W_HEIGHT * 3));
        
        //Джёрма в офисе
        if (state.shock = state.jerma.camera) and (state.timers[state.shockTimer] < SHOCK_EFFECT) and (state.timers[state.shockTimer] > 0) then
          drawSprite(state.camera, 'jerma.png', state.camera.pos, V2.Create(W_WIDTH, W_HEIGHT));
        
        //анимация опускания планшета
        if(state.inGameState <> STATE_LAPTOP) then begin
          state.tabletAnimationFrames := max(0, state.tabletAnimationFrames - frameDelay);
        end
        else begin
          state.tabletAnimationFrames := min(LAPTOP_ANIMATION_LENGTH, state.tabletAnimationFrames + frameDelay);
        end;
        
        if(state.tabletAnimationFrames > 0) then begin
          updateLaptop(additionalOffset);
        end;
        
        case(state.inGameState) of 
          STATE_OFFICE:
            begin
              //перемещение камеры вправо и влево
              var cameraLimit := W_WIDTH * 0.25;
              
              state.camera.target.x += additionalOffset;
              state.camera.target.x := clamp(state.camera.target.x, -cameraLimit, cameraLimit);
              
              //кнопки для офиса
              if(checkActiveZone(V2.Create(0, W_HEIGHT * 0.5 - 25), V2.Create(1400, 50), mouse)) then begin
                changeState(state.camera, state.inGameState, STATE_LAPTOP);
              end;
              
              if(checkActiveZone(V2.Create(0, -W_HEIGHT * 0.5 + 25), V2.Create(1400, 50), mouse)) then
                changeState(state.camera, state.inGameState, STATE_VENT);
              
              if(checkActiveZone(V2.Create(-W_WIDTH * 0.5 + 125, W_HEIGHT * 0.5 - 125), V2.Create(250, 250), mouse)) or 
              (checkActiveZone(V2.Create(W_WIDTH * 0.5 - 125, W_HEIGHT * 0.5 - 125), V2.Create(250, 250), mouse)) then
                changeState(state.camera, state.inGameState, STATE_BACK);
              
              if(state.camera.target.x = cameraLimit) then begin
                drawSprite(state.camera, 'rightButton.png', state.camera.pos + V2.Create(W_WIDTH * 0.5 - 25, 0), V2.Create(50, 500));
                if(checkActiveZone(V2.Create(W_WIDTH * 0.5 - 25, 0), V2.Create(50, 500), mouse)) then
                  changeState(state.camera, state.inGameState, STATE_BACK);
              end;
              if(state.camera.target.x = -cameraLimit) then begin
                drawSprite(state.camera, 'leftButton.png', state.camera.pos - V2.Create(W_WIDTH * 0.5 - 25, 0), V2.Create(50, 500));
                if(checkActiveZone(V2.Create(-W_WIDTH * 0.5 + 25, 0), V2.Create(50, 500), mouse)) then
                  changeState(state.camera, state.inGameState, STATE_BACK);
              end;
              
              //нажатие на двери
              if(state.timers[state.shockReloadTimer] < 0) then begin
                if(checkButtonZone(V2.Create(-W_WIDTH * 0.52, 0), V2.Create(0.36 * W_WIDTH, W_HEIGHT), mouse.gamePos, true)) then begin
                  if(mouse.wentDown) then begin
                    state.timers[state.shockTimer] := SHOCK_DURATION;
                    state.shock := CAMERA_OFFICE_LEFT;
                    state.timers[state.shockReloadTimer] := SHOCK_RELOAD;
                  end;
                end;
                if(checkButtonZone(V2.Create(W_WIDTH * 0.52, 0), V2.Create(0.36 * W_WIDTH, W_HEIGHT), mouse.gamePos, true)) then begin
                  if(mouse.wentDown) then begin
                    state.timers[state.shockTimer] := SHOCK_DURATION;
                    state.shock := CAMERA_OFFICE_RIGHT;
                    state.timers[state.shockReloadTimer] := SHOCK_RELOAD;
                  end;
                end;
              end;
              
              drawSprite(state.camera, 'invertedButton.png', state.camera.pos + V2.Create(0, -W_HEIGHT * 0.5 + 25), V2.Create(1400, 50));
              drawSprite(state.camera, 'button.png', state.camera.pos + V2.Create(0, W_HEIGHT * 0.5 - 25), V2.Create(1400, 50));
            end;
          STATE_VENT:
            begin
              if(checkActiveZone(V2.Create(0, W_HEIGHT * 0.5 - 25), V2.Create(1400, 50), mouse)) then
                changeState(state.camera, state.inGameState, STATE_OFFICE);
              
              //нажатие на вентиляцию
              if(state.timers[state.shockReloadTimer] < 0) then begin
                if(checkButtonZone(V2.Create(0, -W_HEIGHT * 2.03), V2.Create(W_WIDTH * 0.45, W_WIDTH * 0.45), mouse.gamePos, true)) then begin
                  if(mouse.wentDown) then begin
                    state.timers[state.shockTimer] := SHOCK_DURATION;
                    state.shock := CAMERA_VENT;
                    state.timers[state.shockReloadTimer] := SHOCK_RELOAD;
                  end;
                end;
              end;
              
              drawSprite(state.camera, 'button.png', state.camera.pos + V2.Create(0, W_HEIGHT * 0.5 - 25), V2.Create(1400, 50));
              
            end;
          
          STATE_BACK:
            begin
              drawSprite(state.camera, 'rightButton.png', state.camera.pos + V2.Create(W_WIDTH * 0.5 - 25, 0), V2.Create(50, 500));
              drawSprite(state.camera, 'leftButton.png', state.camera.pos - V2.Create(W_WIDTH * 0.5 - 25, 0), V2.Create(50, 500));
              
              if(checkActiveZone(V2.Create(W_WIDTH * 0.5 - 25, 0), V2.Create(50, 500), mouse) or 
              checkActiveZone(V2.Create(-W_WIDTH * 0.5 + 25, 0), V2.Create(50, 500), mouse)) then
                changeState(state.camera, state.inGameState, STATE_OFFICE);
              
            end;
          STATE_LAPTOP:
            begin
              //кнопка возврата для планшета
              if(checkActiveZone(V2.Create(0, W_HEIGHT * 0.5 - 25), V2.Create(1400, 50), mouse)) then begin
                state.inGameState := STATE_OFFICE;
              end;
              
              drawSprite(state.camera, 'button.png', state.camera.pos + V2.Create(0, W_HEIGHT * 0.5 - 25), V2.Create(1400, 50));
            end;
        
        end;
        
        //реализация поведения монстра Джёрма
        jermaAI();
        
        //скример и окончание игры
        if(state.jumpscare <> JUMPSCARE_NONE) then begin
          changeState(state.camera, state.inGameState, STATE_OFFICE);
          state.camera.pos := state.camera.target;
          state.tabletAnimationFrames := 0;
          
          if(state.timers[state.jumpscareTimer] <= 0) then begin
            rewrite(saveFile);
            state.gameState := STATE_GAME_OVER;
          end;
        end;
        var shockReloadLvl := 1 - clamp(state.timers[state.shockReloadTimer] / SHOCK_RELOAD, 0, 1);
        var barHeight := 150 * shockReloadLvl;
        drawSprite(state.camera, 'shockLvl.png', state.camera.pos + V2.Create(-W_WIDTH, -W_HEIGHT) * 0.5 + V2.Create(100, 150), V2.Create(50, 150));
        drawRect(state.camera, state.camera.pos + V2.Create(-W_WIDTH, -W_HEIGHT) * 0.5 + V2.Create(100, 150 + (150 - barHeight) * 0.5), V2.Create(50, barHeight), ARGB(round(55 + 100 * power(shockReloadLvl, 3)), 0, 0, 255));
        
        //отображение времени
        var hours := floor((GAME_LENGTH - state.timers[state.gameTimer]) / GAME_LENGTH * 6);
        drawText(state.camera, state.camera.pos + V2.Create(W_WIDTH * 0.5 - 150, -W_HEIGHT * 0.5 + 100), V2.Create(0, 70), hours + ':00', RGB(10, 10, 255), 'Impact', center);
      end;
    STATE_GAME_OVER:
      begin
        drawText(state.camera, V2.Create(0, 0), V2.Create(0, 120), 'You died', RGB(240, 0, 0));
        if(mouse.wentDown) then
          startTransition(FPS, procedure -> state.gameState := STATE_MENU);
      end;
    STATE_PAUSE:
      begin
        drawText(state.camera, state.camera.pos + V2.Create(0, -300), V2.Create(0, 80), 'Pause', RGB(255, 255, 255));
        
        if(checkPushButton(state.camera.pos, V2.Create(400, 80), mouse.gamePos, 'Save & exit',
          mouse.isDown, FPS, frameDelay, center)) then
          startTransition(FPS, procedure -> begin makeSave(); state.gameState := STATE_MENU end);
        
      end;
  end;
  
  if(state.gameState <> STATE_GAME) then
  begin
    drawStatic(state.camera, state.camera.pos);
    if(state.timers[state.noise.timer] <= 0) and (getRandomFloat(0, 1) > 0.99) then
      makeNoise(2, 8, 50, 150);
  end;
  
  //  textOut(300, 300, timers[jerma.timer], RGB(0, 255, 0));
  
    //очистка ввода с мышки
  mouse.wentDown := false;
  mouse.wentUp := false;
  
  if(not mouse.isDown) then
    btnPushing := 0;
  
  //сохранение прошлых значений координат мышки
  mouse.recentPos := mouse.pos;
  
  if(state.gameState <> STATE_PAUSE) then
  begin
    updateTimers(frameDelay, state.timersLength);
    //перемещение камеры
    state.camera.pos += (state.camera.target - state.camera.pos) * CAMERA_SPEED * frameDelay;
  end
  else
    updateTimers(frameDelay, 2);
  
  updateTransition();
  
  //выходит из программы, если переменная поменялась
  if not running then
    window.Close();
end;

begin
  
  var snd := new Sound('C:\Users\a-rog\Files\Desktop\Projects\Pascalgame\sounds\ambience.wav');
  snd.Play();
  var kek:= new Sound('C:\Users\a-rog\Files\Desktop\Projects\Pascalgame\sounds\static.wav');
  kek.Play();
  
  //подготовка к старту игры  
  //подготовка камер к работе
  //основные свойства камер
  for var i := 0 to CAMERA_COUNT - 1 do
  begin
    cameraObjects[i].cType := CAMERA_TYPE_RECT;
  end;
  cameraObjects[ord(CAMERA_SOLAR)].cType := CAMERA_TYPE_ROUND;
  //пространсвенные свойства для каждой камеры
  cameraObjects[ord(CAMERA_SOLAR)].size.x := 105;
  
  cameraObjects[ord(CAMERA_HALL)].pos.x := 75;
  cameraObjects[ord(CAMERA_HALL)].pos.y := 150;
  cameraObjects[ord(CAMERA_HALL)].size.x := 60;
  cameraObjects[ord(CAMERA_HALL)].size.y := 180;
  
  cameraObjects[ord(CAMERA_CREEPY)].pos.x := -75;
  cameraObjects[ord(CAMERA_CREEPY)].pos.y := 150;
  cameraObjects[ord(CAMERA_CREEPY)].size.x := 60;
  cameraObjects[ord(CAMERA_CREEPY)].size.y := 180;
  
  cameraObjects[ord(CAMERA_DARK)].pos.x := -165;
  cameraObjects[ord(CAMERA_DARK)].pos.y := 150;
  cameraObjects[ord(CAMERA_DARK)].size.x := 60;
  cameraObjects[ord(CAMERA_DARK)].size.y := 60;
  
  cameraObjects[ord(CAMERA_RING)].pos.x := 0;
  cameraObjects[ord(CAMERA_RING)].pos.y := -150;
  cameraObjects[ord(CAMERA_RING)].size.x := 120;
  cameraObjects[ord(CAMERA_RING)].size.y := 90;
  
  cameraObjects[ord(CAMERA_CASINO)].pos.x := -150;
  cameraObjects[ord(CAMERA_CASINO)].pos.y := -105;
  cameraObjects[ord(CAMERA_CASINO)].size.x := 120;
  cameraObjects[ord(CAMERA_CASINO)].size.y := 90;
  
  cameraObjects[ord(CAMERA_SPIDER)].pos.x := 210;
  cameraObjects[ord(CAMERA_SPIDER)].pos.y := -150;
  cameraObjects[ord(CAMERA_SPIDER)].size.x := 120;
  cameraObjects[ord(CAMERA_SPIDER)].size.y := 90;
  
  cameraObjects[ord(CAMERA_CAGE)].pos.x := 210;
  cameraObjects[ord(CAMERA_CAGE)].pos.y := 0;
  cameraObjects[ord(CAMERA_CAGE)].size.x := 120;
  cameraObjects[ord(CAMERA_CAGE)].size.y := 90;
  
  cameraObjects[ord(CAMERA_BATH)].pos.x := 210;
  cameraObjects[ord(CAMERA_BATH)].pos.y := 150;
  cameraObjects[ord(CAMERA_BATH)].size.x := 120;
  cameraObjects[ord(CAMERA_BATH)].size.y := 90;
  
  reset(saveFile, 'save.txt');
  
  state.gameState := STATE_WARNING;
  transition.timer := addTimer(0);
  btnPushing := 0;
  startTransition(FPS, procedure -> nothing());
  state.timers[transition.timer] := -1;
  state.noise.timer := addTimer(-1);
  
  //параметры окна
  window.Caption := 'One night at Jerma`s';
  window.SetSize(System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width,
                System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
  window.IsFixedSize := true;
  
  randomize;
  recentFrame := getTime() + 100000;
  
  //задаём события мышки
  OnMouseDown := mouseDown;
  OnMouseMove := mouseMove;
  OnMouseUp := mouseUp;
  OnKeyDown := keyDown;
  OnClose := procedure ->
  if((state.gameState = STATE_GAME) or (state.gameState = STATE_PAUSE)) and (state.timers[state.jumpscareTimer]<0) then
    makeSave();
  
  //переменная работы программы
  running := true;
  
  BeginFrameBasedAnimation(cycle, FPS);
  
end.