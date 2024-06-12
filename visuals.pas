{$F+}
//Модуль "Визуал" для визуальных эффектов
unit visuals;
interface

  uses saveState, drawing, math, timer;

  //таймер для анимаций перехода
  var 
    transition: record
      timer: integer;
      duration: real;
      proc: procedure();
    end;
    
    //переменная длительности кадра в миллисекундах
    recentFrame: real;
    //относительная задержка по сравнением с эталонным временем кадра
    frameDelay: real;

  //помехи на экране
  //пустая процедура
  procedure nothing();
  //создание помех
  procedure makeNoise(minTime, maxTime, minVal, maxVal: real);
  //прорисовка помех
  procedure updateNoise();
  procedure drawStatic(camera: CameraType; x,y:real);
  //процедуры плавного перехода
  procedure startTransition(duration: real; proc: procedure());
  procedure updateTransition();

implementation

  procedure nothing;
  begin
    
  end;
  
  procedure makeNoise;
  begin
    state.timers[state.noise.timer] := getRandomFloat(minTime, maxTime);
    state.noise.posY := getRandomFloat(-W_HEIGHT * 0.5, W_HEIGHT * 0.5);
    state.noise.sizeY := getRandomFloat(minVal, maxVal);
  end;
  
  //прорисовка помех
  procedure updateNoise;
  begin
    if(state.timers[state.noise.timer] > 0) then begin
      drawRect(state.camera, state.camera.x,state.camera.y + state.noise.posY, W_WIDTH, state.noise.sizeY, RGB(255, 255, 255));
    end;
  end;
  
  procedure drawStatic;
  begin  
    //прорисовка помех
    drawSprite(state.camera, 'static/' + getRandomInt(1, 8) + '.png', x,y, W_WIDTH,W_HEIGHT);
    
    updateNoise();
  end;
  
  //процедуры плавного перехода
  procedure startTransition;
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
  
  procedure updateTransition;
  begin
    var transitionLvl := clamp(1 - abs(state.timers[transition.timer]) / (transition.duration * 0.5), 0, 1);
    drawRect(state.camera, state.camera.x,state.camera.y, W_WIDTH, W_HEIGHT, ARGB(round(transitionLvl * 255), 0, 0, 0));
    if(state.timers[transition.timer] >= 0) and (state.timers[transition.timer] - 1 / frameDelay <= 0) then
      transition.proc();
  end;

begin

  transition.timer := addTimer(state.timers,state.timersLength,0);
  
end.