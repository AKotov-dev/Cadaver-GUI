unit LSFolderTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, Forms, Controls, ComCtrls;

type
  StartLSFolder = class(TThread)
  private

    { Private declarations }
  protected
  var
    S: TStringList;

    procedure Execute; override;

    procedure UpdateSDBox;
    procedure ShowProgress;

  end;

implementation


uses unit1;

{ TRD }

//Апдейт текущего каталога в './..'
procedure StartLSFolder.Execute;
var
  ExProcess: TProcess;
begin
  try
    Synchronize(@ShowProgress);

    S := TStringList.Create;
    FreeOnTerminate := True; //Уничтожить по завершении

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    //Ошибки не выводим, только список, ждём окончания потока
    ExProcess.Options := [poWaitOnExit, poUsePipes];

    //ls текущего каталога Вариант-1
    //ExProcess.Parameters.Add('echo -e "cd ' + '''' + MainForm.GroupBox2.Caption +
    //  '''' + '\nls" | cadaver ' + Server + ' | grep -E "^Coll:|^ " | sed ' +
    //  '''' + 's/^ *//' + '''' + ' | sed ' + '''' + 's/^Coll:   /\//' +
    //  '''' + ' | awk -F "   " ' + '''' + '{print $1}' + '''');

    //Вариант-2
    //Разделяем 4-ре последних столбца ";" и выводим цельный столбец-1 с заменой "Coll: " на "/"
    //https://question-it.com/questions/4338789/awk-vyvesti-vse-krome-poslednih-n-stolbtsov
    //ExProcess.Parameters.Add('echo -e "cd ' + '''' + MainForm.GroupBox2.Caption +
    //  '''' + '\nls" | cadaver ' + Server + ' | grep -E "^Coll:|^ " | awk ' +
    //  '''' + '{for (i=1;i<NF;i++) printf "%s%s",$i,(i+5>NF?";":FS);print $NF}' +
    //  '''' + ' | sed "s/^Coll: /\//" | cut -d";" -f1');

    //Вариант-3
    //ExProcess.Parameters.Add('echo -e "cd ' + '''' + MainForm.GroupBox2.Caption +
    //  '''' + '\nls" | cadaver ' + Server + ' | grep -E "^Coll:|^ " | awk ' +
    //  '''' + '{ last=";"$(NF-2)";"$(NF-1)";"$NF; NF-=4; print $0 last}' +
    //  '''' + ' | sed "s/^Coll: /\//" | cut -d";" -f1');

    //Вариант-4
    ExProcess.Parameters.Add('echo -e "cd ' + '''' + MainForm.GroupBox2.Caption +
      '''' + '\nls" | cadaver ' + Server +
      ' | grep -E "^Coll:|^ " | rev | sed -r "s/(\s+)?\S+//1" | sed -r "s/(\s+)?\S+//1" | '
      + 'sed -r "s/(\s+)?\S+//1" | sed -r "s/(\s+)?\S+//1" | rev | sed "s/^ *//" |  sed "s/ *$//" | sed "s/^Coll:   /\//"');


    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    Synchronize(@UpdateSDBox);

  finally
    // Synchronize(@HideProgress);
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

//Начало операции
procedure StartLSFolder.ShowProgress;
begin
  MainForm.ProgressBar1.Style := pbstMarquee;
  MainForm.ProgressBar1.Refresh;
  Application.ProcessMessages;
end;

{ БЛОК ВЫВОДА ls в SDBox }
procedure StartLSFolder.UpdateSDBox;
begin
  with MainForm do
  begin
    //Вывод обновленного списка
    SDBox.Items.Assign(S);

    //Апдейт содержимого
    SDBox.Refresh;

    //Фокусируем
    SDBox.SetFocus;

    //Если список не пуст - курсор в "0"
    if SDBox.Count <> 0 then
      SDBox.ItemIndex := 0;

    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Repaint;
    Application.ProcessMessages;
  end;
end;

end.
