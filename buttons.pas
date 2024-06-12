{$F+}
//Модуль "Кнопки" содержит функции создания кнопок
unit buttons;

interface
  uses drawing, math, input, saveState, visuals;
  
  var
    //время удерживания кнопки
    btnPushing: real;

  //проверка наведения на активную зону
  //Активная зона - вид взаимодействия пользователя с программой, при котором пользователь наводит мышью на 
  //определённую область экрана, чтобы произошло событие.
  function checkActiveZone(x,y,width,height: real; mouse: MouseType): boolean; 
  //проверка нажатия на кнопку
  function checkButtonZone(x,y,width,height,mouseX,mouseY: real; condition: boolean := true): boolean; 
  //проверка нажатия на кнопку меню
  function checkNormalButton(x,y, width,height,mouseX,mouseY: real; str: string; condition: boolean; align: Alignment): boolean;
  function checkPushButton(x,y,width,height,mouseX,mouseY:real; str: string; condition: boolean; holdingLength: real; frameDelay: real; align: Alignment): boolean;

implementation
  //проверка наведения на активную зону
  //Активная зона - вид взаимодействия пользователя с программой, при котором пользователь наводит мышью на 
  //определённую область экрана, чтобы произошло событие.
  function checkActiveZone: boolean;
  begin
    var res := false;
    var left := x - width * 0.5;
    var right := x + width * 0.5;
    var top := y - height * 0.5;
    var bottom := y + height * 0.5;
    if(mouse.x >= left) and (mouse.x <= right) and (mouse.y >= top) and (mouse.y <= bottom) and
      not ((mouse.recentPosX >= left) and (mouse.recentPosX <= right) and 
      (mouse.recentPosY >= top) and (mouse.recentPosY <= bottom)) then
      res := true;
    
    result := res;
  end;
  
  //проверка нажатия на кнопку
  function checkButtonZone: boolean;
  begin
    var res := false;
    var left := x - width * 0.5;
    var right := x + width * 0.5;
    var top := y - height * 0.5;
    var bottom := y + height * 0.5;
    if(mouseX >= left) and (mouseX <= right) and (mouseY >= top) and (mouseY <= bottom) and condition then
      res := true;
    
    result := res;
  end;
  
  //проверка нажатия на кнопку меню
  function checkNormalButton: boolean;
  begin
    var res := false;
    if(checkButtonZone(x,y, width,height, mouseX,mouseY, state.timers[transition.timer]<=0)) then
    begin
      if(getRandomFloat(0, 1) > 0.95) then 
        str[getRandomInt(1, length(str))] := chr(getRandomInt(0, 90));
      if(getRandomFloat(0, 1) > 0.95) then begin
        x += getRandomFloat(-5, 5);
        y += getRandomFloat(-5, 5);
      end;
      if(condition) then
        res := true;
    end;
    
    drawText(state.camera, x,y, width,height, str, ARGB(255,255, 255, 255), DEAFAULT_FONT, align);
    
    result := res;
  end;
  
  function checkPushButton: boolean;
  begin
    var res := false;
    if(checkButtonZone(x,y, width,height, mouseX,mouseY, state.timers[transition.timer]<0)) then
    begin
      x+=getRandomInt(-10, 10)* btnPushing / holdingLength;
      y+=getRandomInt(-10, 10)* btnPushing / holdingLength;
      if(condition) then begin
        btnPushing += 1/frameDelay;
        if(btnPushing >= holdingLength) then
          res := true;
      end;
    end;
    
    checkNormalButton(x,y, width,height, mouseX,mouseY, str, condition, align);
    
    result := res;
  end;
  
begin
  btnPushing := 0;  
end.