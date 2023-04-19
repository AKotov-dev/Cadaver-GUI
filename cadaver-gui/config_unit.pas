unit config_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, Process, LCLType;

type

  { TConfigForm }

  TConfigForm = class(TForm)
    ServerBox: TComboBox;
    Label3: TLabel;
    OkBtn: TBitBtn;
    CloseBtn: TBitBtn;
    LoginEdit: TEdit;
    PasswordEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure OkBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  ConfigForm: TConfigForm;

implementation

uses unit1;

{$R *.lfm}

{ TConfigForm }

procedure TConfigForm.OkBtnClick(Sender: TObject);
var
  S: TStringList;
begin
  //Обновить правую панель, если подключение состоялось
  left_panel := False;
  //Делаем новый ~/.netrc и сохраняем
  try
    S := TStringList.Create;
    S.Add('default');
    S.Add('login ' + Trim(LoginEdit.Text));
    S.Add('password ' + Trim(PasswordEdit.Text));
    S.Add('#server ' + Trim(ServerBox.Text));

    S.SaveToFile(GetUserDir + '.netrc');

    //Сервер для команд
    if RunCommand('/bin/bash',
      ['-c', 'grep "#server " ~/.netrc | sed "s/#server //"'], Server) then
      Server := Trim(Server);

    //Пробуем открыть корень облака
    MainForm.GroupBox2.Caption := '.';
    MainForm.StartProcess('killall cadaver');
    MainForm.StartLS;
  finally
    S.Free;
  end;
end;

procedure TConfigForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ConfigForm.Close;
end;

procedure TConfigForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

//Чтение параметров напрямую из ~/.netrc
procedure TConfigForm.FormShow(Sender: TObject);
var
  S: ansistring;
begin
  if FileExists(GetUserDir + '.netrc') then
  begin
    if RunCommand('/bin/bash',
      ['-c', 'grep "login " ~/.netrc | sed "s/login //"'], S) then
      LoginEdit.Text := Trim(S);

    if RunCommand('/bin/bash',
      ['-c', 'grep "password " ~/.netrc | sed "s/password //"'], S) then
      PasswordEdit.Text := Trim(S);

    if RunCommand('/bin/bash',
      ['-c', 'grep "#server " ~/.netrc | sed "s/#server //"'], S) then
      ServerBox.Text := Trim(S);
  end;
end;

end.
