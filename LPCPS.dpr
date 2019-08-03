program LPCPS;

uses
  Vcl.Forms,
  LPCP_SENDER in 'LPCP_SENDER.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
