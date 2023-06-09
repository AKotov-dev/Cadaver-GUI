unit S3CommandTRD;

{$mode objfpc}{$H+}

interface

uses
  Forms, Classes, Process, SysUtils, ComCtrls;

type
  StartS3Command = class(TThread)
  private

    { Private declarations }
  protected
  var
    Log: TStringList;

    procedure Execute; override;

    procedure ShowLog;
    procedure StartProgress;
    procedure StopProgress;

  end;

implementation

uses Unit1;

{ TRD }

procedure StartS3Command.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса
    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожить по завершении
    Log := TStringList.Create;

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(cmd);

    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    //, poWaitOnExit (синхронный вывод)

    ExProcess.Execute;

    //Выводим лог динамически
    while ExProcess.Running do
    begin
      Log.LoadFromStream(ExProcess.Output);

      //Выводим лог
      Log.Text := Trim(Log.Text);

      //  sleep(100);
      if Log.Count <> 0 then
        Synchronize(@ShowLog);
    end;

  finally
    Synchronize(@StopProgress);
    Log.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт индикатора
procedure StartS3Command.StartProgress;
begin
  with MainForm do
  begin
    LogMemo.Clear;

    //Запрещаем параллельное копирование
    Panel4.Enabled := False;
    Panel3.Enabled := False;

    //Метка отмены копирования
    Panel4.Caption := SCancelCopyng;

    Application.ProcessMessages;
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.Repaint;
  end;
end;

//Стоп индикатора
procedure StartS3Command.StopProgress;
begin
  with MainForm do
  begin
    //Останов индикатора
    Application.ProcessMessages;
    MainForm.ProgressBar1.Style := pbstNormal;
    MainForm.ProgressBar1.Repaint;

    //Метка отмены копирования
    Panel4.Caption := '';

    //Обновление каталогов назначения (выборочно)
    if left_panel then
      CompDirUpdate
    else
      StartLS;
  end;

  //Очищаем команду для корректного "Esc" (нормальный выход)
  cmd := '';
end;

//Вывод лога
procedure StartS3Command.ShowLog;
var
  i: integer;
begin
  //Вывод построчно
  for i := 0 to Log.Count - 1 do
    MainForm.LogMemo.Lines.Append(Log[i]);

  //Курсор в конец текста
  MainForm.LogMemo.SelStart := Length(MainForm.LogMemo.Text);

  //Если строк > 500 - очистить (файл может быть большим)
  if MainForm.LogMemo.Lines.Count > 500 then MainForm.LogMemo.Clear;
end;

end.
