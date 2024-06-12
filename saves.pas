//Модуль "Сохранения" для сохранения состояния игры
unit saves;

interface
  uses saveState;  
    
  //процедуры работы с файлом сохранения
  procedure loadSave();  
  procedure makeSave();
    
  implementation
    //процедуры работы с файлом сохранения
    procedure loadSave;
    begin
      var f: file;
      reset(f,'save.txt');
      var newState: StateType;
      read(f, newState);
      state:=newState;
      close(f);
    end;
    
    procedure makeSave;
    begin
      var f : file;
      reset(f,'save.txt');
      if(state.gameState = STATE_GAME) or (state.gameState = STATE_PAUSE) and 
        (state.timers[state.jumpscareTimer]<0) then
      begin
        state.gameState := STATE_GAME;
        rewrite(f);
        write(f, state);
      end;
      close(f);
    end;
  end.