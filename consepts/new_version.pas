program Game;

//бибилиотека прорисовки
uses GraphWpf;

//модуль устройств ввода
type
  MouseType = record
    x: real;
    y: real;
    isDown: boolean;
    wentDown: boolean;
    wentUp: boolean;
  end;

var
  mouse: MouseType;
  running:boolean;

procedure MouseDown(x, y:real; mb: integer);
begin
  mouse.isDown := true;
  mouse.wentDown := true;
end;

procedure MouseMove(x, y:real; mb: integer);
begin
  mouse.x := x;
  mouse.y := y;
end;

procedure MouseUp(x, y:real; mb: integer);
begin
  mouse.isDown := false;
  mouse.wentUp := false;
end;

procedure ClearMouse(mouse: MouseType);
begin
  mouse.wentDown := false;
  mouse.wentUp := false;
end;

function getTime(): double;
begin
  Result := System.DateTime.Now.ToFileTime / 10000000;
end;

procedure cycle();
begin
  var recentTime := getTime;
  
  Rectangle(mouse.x - 25, mouse.y - 25, 50, 50);
    
  //очистка ввода с мышки
  clearMouse(mouse);
  
  if not running then EndFrameBasedAnimation();
  
  var foo := 1/(getTime - recentTime);
  
  textOut(50,50,foo);
end;

begin
  //задаём параметры мышки
  OnMouseDown := mouseDown;
  OnMouseMove := mouseMove;
  
  //переменная работы программы
  running := true;
  
  window.Maximize;
  
  BeginFrameBasedAnimation(cycle,120);
  
end.