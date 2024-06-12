//Модуль "Математика"
unit math;

interface

  //функции выбора случайного числа из диапазона
  function getRandomFloat(min, max: real): real;
  function getRandomInt(min, max: integer): integer;
  //clamp помещает число в промежуток
  function clamp(val, minv, maxv: real): real;
  //расстояние между точками с заданными координатами
  function distanceBetweenPoints(x1, y1, x2, y2:real): real;

implementation

  function getRandomFloat: real;
  begin
    Result := random() * (max - min) + min;
  end;
  
  function getRandomInt: integer;
  begin
    Result := round(getRandomFloat(min - 0.5, max + 0.49));
  end;
  
  function clamp: real;
  begin
    Result := min(maxv, max(val, minv));
  end;
  
  function distanceBetweenPoints: real;
  begin
    Result := sqrt(sqr(x1 - x2) + sqr(y1 - y2));
  end;
  
begin
  
  randomize;
  
end.