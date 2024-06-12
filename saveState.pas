//Модуль "Сохранённое состояние" содержит параметры игры, которые
//сохраняются в файле
unit saveState;

interface
  uses drawing, input, timer;
  
  const
      //продолжительность игры
      GAME_LENGTH =  FPS * 60 * 2.25;
  
  type
    //типы игровых состояний
    GameStateType = (STATE_WARNING, STATE_MENU, STATE_HOW_TO_PLAY1,STATE_HOW_TO_PLAY2,
    STATE_HOW_TO_PLAY3,STATE_HOW_TO_PLAY4, STATE_HOW_TO_PLAY5,STATE_HOW_TO_PLAY6,STATE_HOW_TO_PLAY7,
    STATE_BEFORE_NIGHT, STATE_GAME, STATE_GAME_OVER,STATE_WIN, STATE_PAUSE);
    InGameStateType = (STATE_OFFICE, STATE_LAPTOP, STATE_BACK, STATE_VENT);
    
    //тип отображения камеры на карте
    MapCameraType = (CAMERA_TYPE_RECT, CAMERA_TYPE_ROUND);
    //порядковый тип для каждой камеры на карте
    Cameras = (CAMERA_HALL, CAMERA_CREEPY, CAMERA_BATH, CAMERA_DARK, CAMERA_SOLAR, CAMERA_CAGE, CAMERA_SPIDER,  CAMERA_RING, 
    CAMERA_CASINO, CAMERA_OFFICE_RIGHT, CAMERA_OFFICE_LEFT, CAMERA_VENT);
    
    JumpscareType = (JUMPSCARE_NONE, JUMPSCARE_JERMA, JUMPSCARE_SPIDER, JUMPSCARE_SUS, JUMPSCARE_RAT);
    
    //тип отображаемой камеры
    MapCameraObjType = record
      x:real;
      y:real;
      width:real;
      height: real;
      cType: MapCameraType;
      color: Color;
    end;

    //сохраняемая запись состояния игры
    StateType = record
      //таймеры и размер массива таймеров
      timersLength: integer;
      timers: TimersType;
      
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
    
    var state: StateType;
    
implementation

begin
   state.noise.timer := addTimer(state.timers,state.timersLength,-1);
   state.shockTimer := addTimer(state.timers, state.timersLength, -1);
   state.shockReloadTimer := addTimer(state.timers, state.timersLength, -1);
end.