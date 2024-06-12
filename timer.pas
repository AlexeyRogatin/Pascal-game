//Модуль "Таймеры" позволяет добавлять таймеры в массив и уменьшать их одновременно
//а также измерять время
unit timer;

interface

type
  TimersType = array [0..100] of real;

//измерение времени в миллисекундах
function getTime(): double;
//добавление нового таймера
function addTimer(var timers: TimersType; var count: integer; time: real): integer;
//обновление таймеров
procedure updateTimers(var timers: TimersType; frameDelay: real; count: integer);

implementation

function getTime: double;
begin
  Result := System.DateTime.Now.ToFileTime / 10000;
end;

function addTimer: integer;
begin
  result := count;
  timers[count] := time;
  count += 1;
end;

procedure updateTimers;
begin
  for var timerIndex := 0 to count - 1 do
    timers[timerIndex] -= 1 / frameDelay;
end;

end.