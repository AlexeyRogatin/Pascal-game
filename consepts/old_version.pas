program Game;

//бибилиотека прорисовки
uses GraphAbc;

//требуемое кол-во кадров в секунду
const FPS_COUNT = 60;
const TIME_PER_FRAME = 1/FPS_COUNT;

//модуль устройств ввода
type MouseType = record
  x:integer;
  y:integer;
  isDown:boolean;
  wentDown:boolean;
  wentUp:boolean;
end;

var mouse: MouseType;
    foo: real;

procedure MouseDown(x,y, mb: integer);
begin
  mouse.isDown := true;
  mouse.wentDown := true;
end;

procedure MouseMove(x,y, mb: integer);
begin
  mouse.x := x;
  mouse.y := y;
end;

procedure MouseUp(x,y, mb:integer);
begin
  mouse.isDown := false;
  mouse.wentUp := true;
end;

procedure ClearMouse(mouse:MouseType);
begin
  mouse.wentDown:=false;
  mouse.wentUp:=false;
end;

function getTime():double;
begin
  Result := System.DateTime.Now.ToFileTime / 10000000;
end;

begin  
  LockDrawing();
  
  //задаём параметры мышки
  OnMouseDown := mouseDown;
  OnMouseMove := mouseMove;
  
  //переменная работы программы
  var running := true;
  
  //на полный экран
  MaximizeWindow();
  
  repeat  
    var recentTime := getTime();
    
    //предварительная очистка окна
    ClearWindow(clWhite);
    
    Rectangle(mouse.x-25,mouse.y-25,mouse.x+25,mouse.y+25);
    
    //очистка ввода с мышки
    clearMouse(mouse);
    textOut(50,50,foo);
    
    redraw;
    
    var time := getTime();
    while((time - recentTime) < TIME_PER_FRAME) do time := getTime();
    foo := 1/(time - recentTime);
    
  until not running;
  
  closeWindow();

end.