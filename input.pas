//Модуль "Ввод" добавляет процедуры обработки нажатий на мышь и клавиши клавиатуры
unit input;

interface
  uses graphWpf;
  
  const
    //эталонные величины
    W_WIDTH = 1920;
    W_HEIGHT = 1080;

  type
  //тип "мышь"
  MouseType = record
    x: real;
    y: real;
    gamePosX: real;
    gamePosY:real;
    recentPosX: real;
    recentPosY:real;
    //нажата
    isDown: boolean;
    //нажалась
    wentDown: boolean;
    //отжалась
    wentUp: boolean;
  end;
  KeyboardKey = record
    wentDown: boolean;
    isDown: boolean;
    wentUp: boolean;
  end;
  
  //мышка
  var mouse: MouseType;
      escKey: KeyboardKey;
  
  //процедуры событий мышки и нажатий
  procedure MouseDown(x, y: real; mb: integer);
  procedure MouseMove(x, y: real; mb: integer);
  procedure MouseUp(x, y: real; mb: integer);
  procedure ClearInput();
  procedure KeyDown(k: Key);
  procedure KeyUp(k: Key);
  
implementation

  //процедуры событий мышки и нажатий
  procedure MouseDown;
  begin
    mouse.isDown := true;
    mouse.wentDown := true;
  end;
  
  procedure MouseMove;
  begin
    mouse.x := x;
    mouse.y := y;
    mouse.x -= window.Width * 0.5;
    mouse.y -= window.Height * 0.5;
    mouse.x *= W_WIDTH / window.Width;
    mouse.y *= W_HEIGHT / window.Height;
  end;
  
  procedure MouseUp;
  begin
    mouse.isDown := false;
    mouse.wentUp := true;
  end;
  
  procedure ClearInput;
  begin
    mouse.wentDown:=false;
    mouse.wentUp:=false;
    escKey.wentDown:=false;
    escKey.wentUp:=false;
  end;
  
  const
    VK_ESC = 13;
  
  procedure KeyDown;
  begin
    if(integer(k) = VK_ESC) then begin
      escKey.wentDown:=true;
      escKey.isDown:=true;
    end;
  end;
  
  procedure KeyUp;
  begin
    if(integer(k) = VK_ESC) then begin
      escKey.wentUp:=true;
      escKey.isDown:=false;
    end;
  end;

end.