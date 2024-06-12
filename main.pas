{$F+}
program main;

//бибилиотеки прорисовки и звука
uses GraphWpf;
uses game,saveState,visuals,timer,input,saves;

begin  
  //подготовка к старту игры 
  
  //задаются начальные значения для переменных, необходимых до начала основной игры
  state.gameState := STATE_WARNING;
  
  //параметры окнаu
  window.Caption := 'One night at Jerma`s';
  window.SetSize(99999,
                99999);
  window.IsFixedSize := true;
  
  //задаётся большое значение первого кадра, чтобы при вычислении frameDelay результат был равен 0
  recentFrame := getTime() + 100000;
  
  //задаём процедуры событий
  OnMouseDown := mouseDown;
  OnMouseMove := mouseMove;
  OnMouseUp := mouseUp;
  OnKeyDown := keyDown;
  OnKeyUp := keyUp;
  OnClose := makeSave;
  
  BeginFrameBasedAnimation(cycle, 120);
  
end.