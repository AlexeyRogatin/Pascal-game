//Модуль "Прорисовка" содержит функции прорисовки, действующие относительно
//эталонного разрешения экрана и камеры, положение которой можно изменять
unit drawing;

interface

uses graphWpf;

//камера, относительно которой происходит прорисовка 
type
  CameraType = record
    x: real;
    y: real;
    targetX: real;
    targetY: real;
  end;
  
  Color = GColor;
  Alignment = Alignment;

const
  //эталонные величины
  W_WIDTH = 1920;
  W_HEIGHT = 1080;
  FPS = 120;
  
  //скорость перемещения камеры
  CAMERA_SPEED = 0.03;
  
  //стандартный шрифт
  DEAFAULT_FONT = 'True Lies';

//функции прорисовки с учётом размеров окна
procedure drawSprite(camera: CameraType; src: string; x, y, width, height: real);
procedure drawRect(camera: CameraType; x, y, width, height: real; clr: Color := RGB(255, 255, 255));
procedure drawCircle(camera: CameraType; x, y, radius: real; clr: Color := RGB(255, 255, 255));
procedure drawText(camera: CameraType; x, y, width, height: real; text: string; color: GColor := RGB(255, 255, 255); 
      fontStr: string := DEAFAULT_FONT; align: Alignment := center);
procedure drawParagraph(camera: CameraType; x, y, width, height: real; indent: real; text: string; 
      color: GColor := RGB(255, 255, 255); fontStr: string := DEAFAULT_FONT; align: Alignment := center);

var ARGB: function(a,r,g,b:byte):Color = ARGB;
var RGB: function(r,g,b:byte):Color = RGB;

implementation

procedure drawSprite;
begin
  src := './bitmaps/' + src;
  x -= camera.x - W_WIDTH * 0.5;
  y -= camera.y - W_HEIGHT * 0.5;
  x := window.Width * 0.5 + (x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  y := window.Height * 0.5 + (y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  
  width *= window.Width / W_WIDTH;
  height *= window.Height / W_HEIGHT;
  drawImage(x - width * 0.5, y - height * 0.5, width, height, src);
end;

procedure drawRect;
begin
  x -= camera.x - W_WIDTH * 0.5;
  y -= camera.y - W_HEIGHT * 0.5;
  x := window.Width * 0.5 + (x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  y := window.Height * 0.5 + (y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  
  width *= window.Width / W_WIDTH;
  height *= window.Height / W_HEIGHT;
  fillRectangle(x - width * 0.5, y - height * 0.5, width, height, clr);
end;

procedure drawCircle;
begin
  x -= camera.x - W_WIDTH * 0.5;
  y -= camera.y - W_HEIGHT * 0.5;
  x := window.Width * 0.5 + (x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  y := window.Height * 0.5 + (y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  var radiusX := radius * window.Width / W_WIDTH;
  var radiusY := radius * window.Height / W_HEIGHT;
  fillEllipse(x, y, radiusX, radiusY, clr);
end;

procedure drawText;
begin
  x -= camera.x - W_WIDTH * 0.5;
  y -= camera.y - W_HEIGHT * 0.5;
  x := window.Width * 0.5 + (x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  y := window.Height * 0.5 + (y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  width *= window.Width / W_WIDTH;
  height *= window.Height / W_HEIGHT;
  Font.Color := color;
  Font.Size := height;
  Font.Name := fontStr;
  drawText(x - width * 0.5, y - height * 0.5, width, height, text, align);
end;

procedure drawParagraph;
begin
  x -= camera.x - W_WIDTH * 0.5;
  y -= camera.y - W_HEIGHT * 0.5;
  x := window.Width * 0.5 + (x - W_WIDTH * 0.5) * window.Width / W_WIDTH;
  y := window.Height * 0.5 + (y - W_HEIGHT * 0.5) * window.Height / W_HEIGHT;
  width *= window.Width / W_WIDTH;
  height *= window.Height / W_HEIGHT;
  height *= window.Width / W_WIDTH;
  indent *= window.Height / W_HEIGHT;
  indent *= window.Width / W_WIDTH;
  var words := text.Split((' '));
  var str := '';
  Font.Color := color;
  Font.Size := height;
  Font.Name := fontStr;
  for var wordIndex := 0 to length(words) - 1 do
  begin
    var textWidth := TextWidth(str + words[wordIndex]);
    if(textWidth <= width) then
      str += words[wordIndex] + ' '
    else begin
      drawText(x - width * 0.5, y - height * 0.5, width, height, str, align);
      y += height * indent;
      str := words[wordIndex] + ' ';
    end;
  end;
  drawText(x - width * 0.5, y - height * 0.5, width, height, str, align);
end;

end.
