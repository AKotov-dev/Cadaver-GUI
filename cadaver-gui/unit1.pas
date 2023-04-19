unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ShellCtrls, Buttons, ComCtrls, IniPropStorage, Types, Process,
  LCLType, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    RenameBtn: TSpeedButton;
    CompDir: TShellTreeView;
    SettingsBtn: TSpeedButton;
    CopyFromPC: TSpeedButton;
    CopyFromBucket: TSpeedButton;
    DelBtn: TSpeedButton;
    AddBtn: TSpeedButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    MkPCDirBtn: TSpeedButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    ProgressBar1: TProgressBar;
    UpdateBtn: TSpeedButton;
    SDBox: TListBox;
    LogMemo: TMemo;
    SelectAllBtn: TSpeedButton;
    InfoBtn: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    UpBtn: TSpeedButton;
    procedure RenameBtnClick(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure CopyFromBucketClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure InfoBtnClick(Sender: TObject);
    procedure SettingsBtnClick(Sender: TObject);
    procedure CopyFromPCClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MkPCDirBtnClick(Sender: TObject);
    procedure UpdateBtnClick(Sender: TObject);
    procedure CompDirUpdate;
    procedure SDBoxDblClick(Sender: TObject);
    procedure SDBoxDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure SelectAllBtnClick(Sender: TObject);
    procedure StartProcess(command: string);
    procedure StartLS;
    procedure StartCmd;
    procedure UpBtnClick(Sender: TObject);

  private

  public

  end;

var
  left_panel: boolean;
  cmd: string;
  server: ansistring; //Сервер, глобально

resourcestring
  SDelete = 'Delete selected object(s)?';
  SOverwriteObject = 'Overwrite existing objects?';
  SObjectExists = 'The folder already exists!';
  SCreateDir = 'Create directory';
  SInputName = 'Enter the name:';
  SCancelCopyng = 'Esc - cancel... ';
  SCloseQuery = 'Copying is in progress! Finish the process?';
  SNewBucket = 'Create a new directory';
  SBucketName = 'Directory name:';
  SRename = 'Rename an object';

var
  MainForm: TMainForm;

implementation

uses config_unit, about_unit, lsfoldertrd, S3CommandTRD;

{$R *.lfm}

{ TMainForm }


//Старт команды
procedure TMainForm.StartCmd;
var
  FStartCmdThread: TThread;
begin
  FStartCmdThread := StartS3Command.Create(False);
  FStartCmdThread.Priority := tpHighest; //tpHigher
end;

//ls в директории . (SDBox)
procedure TMainForm.StartLS;
var
  FLSFolderThread: TThread;
begin
  FLSFolderThread := StartLSFolder.Create(False);
  FLSFolderThread.Priority := tpHighest; //tpHigher
end;

//Уровень вверх
procedure TMainForm.UpBtnClick(Sender: TObject);
var
  i: integer;
begin
  if GroupBox2.Caption <> '.' then
  begin
    for i := Length(GroupBox2.Caption) - 1 downto 1 do
      if GroupBox2.Caption[i] = '/' then
      begin
        GroupBox2.Caption := Copy(GroupBox2.Caption, 1, i - 1);
        break;
      end;
  end;

  //Чтение текущей директории
  StartLS;
end;

//StartCommand (служебные команды)
procedure TMainForm.StartProcess(command: string);
var
  ExProcess: TProcess;
begin
  try
    ExProcess := TProcess.Create(nil);
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);
    ExProcess.Options := [poWaitOnExit, poUsePipes];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Апдейт текущей директории CompDir (ShellTreeView)
procedure TMainForm.CompDirUpdate;
var
  i: integer; //Абсолютный индекс выделенного
  d: string; //Выделенная директория
begin
  try
    //Запоминаем позицию курсора
    i := CompDir.Selected.AbsoluteIndex;
    d := ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected));

    //Обновляем  выбранного родителя
    with CompDir do
      Refresh(Selected.Parent);

    //Курсор на созданную папку
    CompDir.Path := d;
    CompDir.Select(CompDir.Items[i]);
    CompDir.SetFocus;

    //Останов индикатора
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Repaint;
    Application.ProcessMessages;
  except;
    //Если сбой - перечитать корень
    UpdateBtn.Click;
  end;
end;

//Сменить директорию облака (./../..)
procedure TMainForm.SDBoxDblClick(Sender: TObject);
begin
  if SDBox.SelCount <> 0 then
  begin
    if Pos('/', SDBox.Items.Strings[SDBox.ItemIndex]) <> 0 then
    begin
      GroupBox2.Caption := Trim(GroupBox2.Caption + SDBox.Items[SDBox.ItemIndex]);
      StartLS;
    end;
  end;
end;

//Прорисовка иконок панели '.'
procedure TMainForm.SDBoxDrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
begin
  BitMap := TBitMap.Create;
  try
    ImageList1.GetBitMap(0, BitMap);

    with SDBox do
    begin
      Canvas.FillRect(aRect);

      //Вывод текста со сдвигом (общий)
      Canvas.TextOut(aRect.Left + 27, aRect.Top + ItemHeight div 2 -
        Canvas.TextHeight('A') div 2 + 1, Items[Index]);

      //Сверху иконки взависимости от последнего символа ('/')
      if Copy(Items[Index], 0, 1) = '/' then
        //Иконка папки
        ImageList1.GetBitMap(0, BitMap)
      else
        //Иконка файла
        ImageList1.GetBitMap(1, BitMap);

      Canvas.Draw(aRect.Left + 2, aRect.Top + (ItemHeight - 22) div 2 + 2, BitMap);
    end;
  finally
    BitMap.Free;
  end;
end;

//Выделить всё
procedure TMainForm.SelectAllBtnClick(Sender: TObject);
begin
  SDBox.SelectAll;
end;

//Подстановка иконок папка/файл в ShellTreeView
procedure TMainForm.CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
begin
  if FileGetAttr(CompDir.GetPathFromNode(node)) and faDirectory <> 0 then
    Node.ImageIndex := 0
  else
    Node.ImageIndex := 1;
  Node.SelectedIndex := Node.ImageIndex;
end;

//Копирование из облака на компьютер
procedure TMainForm.CopyFromBucketClick(Sender: TObject);
var
  i: integer;
  c: string;
  e: boolean;
begin
  //Флаг выбора панели
  left_panel := True;

  c := '';
  cmd := '';  //Команда
  e := False; //Флаг совпадения файлов/папок (перезапись)

  //Если ничего не выбрано - выход
  if SDBox.SelCount = 0 then Exit;

  for i := 0 to SDBox.Count - 1 do
  begin
    if SDBox.Selected[i] then
    begin
      if not e then
        if FileExists(ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
          SDBox.Items[i]) then e := True;

      if Pos('/', SDBox.Items[i]) = 0 then
        c := 'echo "get ' + '''' + GroupBox2.Caption + '/' +
          SDBox.Items[i] + '''' + ' ' + '''' +
          ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
          SDBox.Items[i] + '''' + '" | cadaver ' + Server
      else
        c := 'echo "Сrawling the directory: ' + SDBox.Items[i] + '"; sleep 1';

      cmd := c + '; ' + cmd;
    end;
  end;

  //Если есть совпадения (перезапись файлов)
  if e and (MessageDlg(SOverwriteObject, mtConfirmation, [mbYes, mbNo], 0) <>
    mrYes) then
    exit;

  StartCmd;
end;

//Предупреждение о завершении обмена с облаком, если в прогрессе
procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if cmd <> '' then
    if MessageDlg(SCloseQuery, mtWarning, [mbYes, mbCancel], 0) <> mrYes then
      Canclose := False
    else
    begin
      StartProcess('killall cadaver');
      CanClose := True;
    end;
end;

//Esc - отмена операций
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if key = VK_ESCAPE then
  begin
    //Если копирование выполняется - отменяем
    if cmd <> '' then
    begin
      StartProcess('killall cadaver');
      LogMemo.Append('Cadaver-GUI: Esc - Cancellation of the operation...');
    end;
  end;
end;

//Форма About
procedure TMainForm.InfoBtnClick(Sender: TObject);
begin
  AboutForm := TAboutForm.Create(Application);
  AboutForm.ShowModal;
end;

//Создание нового каталога
procedure TMainForm.AddBtnClick(Sender: TObject);
var
  S: string;
begin
  S := '';
  repeat
    if not InputQuery(SNewBucket, SBucketName, S) then
      Exit
  until S <> '';

  cmd := 'echo "mkcol ' + '''' + GroupBox2.Caption + '/' + Trim(S) +
    '''' + '" | cadaver ' + Server;

  left_panel := False;

  //Создаём новый каталог и показываем/обновляем список
  MainForm.StartCmd;
end;


//Переименование Файлов/Каталогов
procedure TMainForm.RenameBtnClick(Sender: TObject);
var
  S: string;
begin
  if SDBox.SelCount = 0 then Exit;

  S := StringReplace(SDBox.Items[SDBox.ItemIndex], '/', '',
    [rfReplaceAll, rfIgnoreCase]);

  repeat
    if not InputQuery(SRename, SInputName, S) then
      Exit
  until S <> '';

  cmd := 'echo "move ' + '''' + GroupBox2.Caption + '/' +
    SDBox.Items[SDBox.ItemIndex] + '''' + ' ' + '''' + GroupBox2.Caption +
    '/' + S + '''' + '" | cadaver ' + Server;

  left_panel := False;

  //Создаём новый каталог и показываем/обновляем список
  MainForm.StartCmd;
end;


//Форма конфигурации ~/.netrc
procedure TMainForm.SettingsBtnClick(Sender: TObject);
begin
  ConfigForm := TConfigForm.Create(Application);
  ConfigForm.ShowModal;
end;

//Копирование с компа в облако
procedure TMainForm.CopyFromPCClick(Sender: TObject);
var
  i, sd: integer;
  c: string;
  e: boolean;
begin
  //Флаг выбора панели
  left_panel := False;
  //Сборка единой команды
  c := '';
  //Флаг совпадения имени
  e := False;
  //Команда
  cmd := '';

  //Если ничего не выбрано или выбран весь домашний каталог - Выход
  if (CompDir.Items.SelectionCount = 0) or (CompDir.Items.Item[0].Selected) then Exit;

  for i := 0 to CompDir.Items.Count - 1 do
  begin
    if CompDir.Items[i].Selected then
    begin
      //Ищем совпадения (перезапись объектов)
      if not e then
        for sd := 0 to SDBox.Count - 1 do
        begin
          if CompDir.Items[i].Text = ExcludeTrailingPathDelimiter(
            SDBox.Items[sd]) then
            e := True;
        end;

      c := 'echo "put ' + '''' + CompDir.Items[i].GetTextPath +
        '''' + ' ' + '''' + GroupBox2.Caption + '/' + CompDir.Items[i].Text +
        '''' + '" | cadaver ' + Server;

      cmd := c + '; ' + cmd;
    end;
  end;

  //Если есть совпадения (перезапись файлов)
  if e and (MessageDlg(SOverwriteObject, mtConfirmation, [mbYes, mbNo], 0) <>
    mrYes) then
    exit;

  StartCmd;
end;

//Удаление объекта(ов)
procedure TMainForm.DelBtnClick(Sender: TObject);
var
  i: integer;
  c: string; //сборка команды...
begin
  //Удаление объектов (файлов и папок)
  if (SDBox.SelCount = 0) or (MessageDlg(SDelete, mtConfirmation, [mbYes, mbNo], 0) <>
    mrYes) then
    exit;

  //Команда в поток
  cmd := '';
  //Сборка команды
  c := '';

  //Флаг выбора панели
  left_panel := False;

  for i := 0 to SDBox.Count - 1 do
  begin
    if SDBox.Selected[i] then
    begin
      if Pos('/', SDBox.Items[i]) <> 0 then
        c := 'echo "rmcol ' + '''' + GroupBox2.Caption + SDBox.Items[i] +
          '''' + '" | cadaver ' + Server
      else
        c := 'echo "delete ' + '''' + GroupBox2.Caption + '/' +
          SDBox.Items[i] + '''' + '" | cadaver ' + Server;

      //Собираем команду
      cmd := c + '; ' + cmd;
    end;
  end;

  StartCmd;
end;

//Домашняя папка юзера - корень
procedure TMainForm.FormCreate(Sender: TObject);
begin
  //Очищаем переменную команды для потока
  cmd := '';

  CompDir.Root := ExcludeTrailingPathDelimiter(GetUserDir);
  CompDir.Items.Item[0].Selected := True;

  //Директория конфигураций
  if not DirectoryExists(GetUserDir + '.config') then
    MkDir(GetUserDir + '.config');

  IniPropStorage1.IniFileName := GetUserDir + '.config/cadaver-gui.conf';

  //Server to connect
  if RunCommand('/bin/bash', ['-c', 'grep "#server " ~/.netrc | sed "s/#server //"'],
    Server) then
    Server := Trim(Server);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  Caption := Application.Title;
  IniPropStorage1.Restore;

  //Коррекция размеров при масштабировании в Plasma
  Panel3.Height := CopyFromPC.Height + 14;
  Panel4.Height := Panel3.Height;

  //Проверяем подключение выводим ошибки в LogMemo = StartLS (.)
  StartLS;
end;

//Создать каталог на компьютере
procedure TMainForm.MkPCDirBtnClick(Sender: TObject);
var
  S: string;
begin
  //Флаг выбора панели
  left_panel := False;

  S := '';
  repeat
    if not InputQuery(SCreateDir, SInputName, S) then
      Exit
  until S <> '';

  //Если есть совпадения (перезапись файлов)
  if DirectoryExists(IncludeTrailingPathDelimiter(
    ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected))) + S) then
  begin
    MessageDlg(SObjectExists, mtWarning, [mbOK], 0);
    Exit;
  end;
  //Создаём директорию
  MkDir(IncludeTrailingPathDelimiter(
    ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected))) + S);

  //Обновляем содержимое выделенного нода
  CompDirUpdate;
end;

//Перечитываем домашнюю папку на компьютере
procedure TMainForm.UpdateBtnClick(Sender: TObject);
begin
  with CompDir do
  begin
    Select(CompDir.TopItem, [ssCtrl]);
    Refresh(CompDir.Selected.Parent);
    Select(CompDir.TopItem, [ssCtrl]);
    SetFocus;
  end;
end;

end.
