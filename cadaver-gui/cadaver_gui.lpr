program cadaver_gui;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
  cthreads,   {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  config_unit,
  about_unit;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='Cadaver-GUI v1.0';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
