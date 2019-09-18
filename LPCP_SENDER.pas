unit LPCP_SENDER;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IniFiles, Vcl.StdCtrls, sLabel, CPort,
  Vcl.ComCtrls, sStatusBar, sSkinManager, Vcl.Buttons, sBitBtn, Vcl.ExtCtrls,
  sEdit, sSpinEdit, sComboBox, sButton, sPanel, acSlider, sCheckBox, CPortCtl,
  sMemo, sGroupBox, Registry;

type
  TForm1 = class(TForm)
    sSkinManager1: TsSkinManager;
    sStatusBar1: TsStatusBar;
    ComPort1: TComPort;
    ResetButton: TsBitBtn;
    AddButton: TsBitBtn;
    RunTimer: TTimer;
    StartTime: TsTimePicker;
    StartEdit: TsEdit;
    StopEdit: TsEdit;
    StopTime: TsTimePicker;
    NameComboBox: TsComboBox;
    EnabledCheckBox: TsCheckBox;
    RunSlider: TsSlider;
    LogMemo: TsMemo;
    GroupBox2: TsGroupBox;
    GroupBox1: TsGroupBox;
    CheckTimer: TTimer;
    DelButton: TsBitBtn;
    LogCheckBox: TsCheckBox;
    SlideOffLabel: TsLabel;
    SlideOnLabel: TsLabel;
    TrayIcon1: TTrayIcon;
    StartCheckBox: TsCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
    procedure RunTimerTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AddButtonClick(Sender: TObject);
    procedure StopEditChange(Sender: TObject);
    procedure StartEditChange(Sender: TObject);
    procedure NameComboBoxChange(Sender: TObject);
    procedure NameComboBoxSelect(Sender: TObject);
    procedure RunSliderChanging(Sender: TObject; var CanChange: Boolean);
    procedure NameComboBoxEnter(Sender: TObject);
    procedure CheckTimerTimer(Sender: TObject);
    procedure NameComboBoxExit(Sender: TObject);
    procedure LogCheckBoxClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure DelButtonClick(Sender: TObject);
    procedure StartCheckBoxClick(Sender: TObject);
  private
    { Private declarations }
    procedure FillStatusBar();
    procedure FillCommand(pStart: Boolean; Conf: TIniFile);
    procedure DellCommand();
    procedure StatIni(pStart: Boolean);
    procedure SecNull();
    procedure SetupCPort(pStart: Boolean);
  public
    { Public declarations }
  end;

type
  //Structure
  TCommand = Record
    Index: Integer;
    Name: String[20];
    CmdStart: String[20];
    TimeStart: TTime;
    CmdStop: String[20];
    TimeStop: TTime;
    Enabled: Boolean;
    Running: Boolean; //Control Start/Stop Script on RunTimer (Memory Only DO NOT INCLUDE ON INI)
end;

var
  Form1: TForm1;
  Command: array of TCommand;

implementation

{$R *.dfm}

procedure SetAutoStart(AppName, AppTitle: string; bRegister: Boolean);
const
  RegKey = '\Software\Microsoft\Windows\CurrentVersion\Run';
  // or: RegKey = '\Software\Microsoft\Windows\CurrentVersion\RunOnce';
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    if Registry.OpenKey(RegKey, False) then
    begin
      if bRegister = False then
        Registry.DeleteValue(AppTitle)
      else
        Registry.WriteString(AppTitle, AppName);
    end;
  finally
    Registry.Free;
  end;
end;

procedure TForm1.DelButtonClick(Sender: TObject);
begin
  DellCommand();
end;

procedure TForm1.DellCommand();
var
  I, Item: Integer;
begin
  I := NameComboBox.ItemIndex;
  Item := NameComboBox.ItemIndex;
  //Command[I].Index := null;
  if (I = 0) then
    begin
      for I := 1 to 4 do
        begin
          Command[I-1].Index := Command[I].Index;
          Command[I-1].Name := Command[I].Name;
          Command[I-1].CmdStart := Command[I].CmdStart;
          Command[I-1].TimeStart := Command[I].TimeStart;
          Command[I-1].CmdStop := Command[I].CmdStop;
          Command[I-1].TimeStop := Command[I].TimeStop;
          Command[I-1].Enabled := Command[I].Enabled;
          Command[I-1].Running := Command[I].Running;
        end;
        NameComboBox.Items.Delete(Item);
        SetLength(Command, 5-1);
        showmessage('here');
    end;
end;

//Time to Start can't be small than Time to Stop. Remember, using only TTime, not TDateTime so It doesn't have Days or Month
function CheckStartStopTime(pStart, pStop: TTime): Boolean;
begin
  if (pStart <= pStop) then Result := True
  else
    Result := False;
end;

procedure TForm1.CheckTimerTimer(Sender: TObject);
var
  ItemName: String;
  I: Integer;
begin
  //Change Show/Hide Options [New, Edit, Del]
  I := NameComboBox.ItemIndex;
  if (ItemName = '') then ItemName := ' ';
  if (NameComboBox.Text = Command[I].Name) then
    begin
      AddButton.Caption := 'Edit';
      AddButton.Width := 58;
      DelButton.Enabled := True;
      DelButton.Visible := True;
    end
  else
    begin
      AddButton.Caption := 'New';
      AddButton.Width := 120;
      DelButton.Enabled := False;
      DelButton.Visible := False;
    end;
end;

procedure TForm1.FillCommand(pStart: Boolean; Conf: TIniFile);
var
  I: Integer;
  Tmp: String;
begin
  if (pStart) then
    begin
      for I := 0 to 4 do
        begin
          Tmp := Conf.ReadString(IntToStr(I), 'Name', ''); //Fix Null Item To Be Added
          if (Tmp <> '') then                              //To the Command List
            begin
              //if (CheckStartStopTime(Command[)) then blablabla
              //Load Ini to Command Record
              Command[I].Index := Conf.ReadInteger(IntToStr(I), 'Index', 0);
              Command[I].Name := Conf.ReadString(IntToStr(I), 'Name', '');
              NameComboBox.Items.Add(Command[I].Name);
              Command[I].CmdStart := Conf.ReadString(IntToStr(I), 'CmdStart', '');
              Command[I].CmdStop := Conf.ReadString(IntToStr(I), 'CmdStop', '');
              Command[I].TimeStart := Conf.ReadTime(IntToStr(I), 'TimeStart', 0); // it should be checked before added
              Command[I].TimeStop := Conf.ReadTime(IntToStr(I), 'TimeStop', 0);   // it should be checked before added
              Command[I].Enabled := Conf.ReadBool(IntToStr(I), 'Enabled', True);
            end;
        end;
    end
  else
    begin
      try
        for I := 0 to 4 do
          begin
            if (Command[I].Name = '')then break;
          end;
      finally
        if (I <= 4) then
          begin
            Command[I].Index:= I;
            Command[I].Name:= NameComboBox.Text;
            Command[I].CmdStart:= StartEdit.Text;
            Command[I].CmdStop:= StopEdit.Text;
            Command[I].TimeStart:= StartTime.Time;
            Command[I].TimeStop:= StopTime.Time;
            Command[I].Enabled:= EnabledCheckBox.Checked;
            NameComboBox.Items.Add(Command[I].Name);
            Application.MessageBox('New Item Added Successfully!', 'New Item', MB_ICONINFORMATION + MB_OK);
          end
        else
          Application.MessageBox('Unable to add a New Item. Max: 5.', 'Item Error', MB_ICONERROR + MB_OK);
      end;
    end;
end;

procedure TForm1.SetupCPort(pStart: Boolean);
begin
  //Setup to Configurate ComPort
  try
    ComPort1.ShowSetupDialog;
  finally
    if (pStart) then Application.MessageBox('Settings Saved Successfully.', 'ComPort', MB_ICONWARNING + MB_OK)
    else
      Application.MessageBox('Settings Changed Successfully.', 'ComPort', MB_ICONWARNING + MB_OK);
    FillStatusBar();
  end;
end;

procedure TForm1.SecNull();
begin
  //Check if All Edits are Different from Null, Before add a New Item to ComboBox and Record
  if ((StartEdit.Text <> '') and (StopEdit.Text <> '') and (NameComboBox.Text <> '')) then
    AddButton.Enabled := True
  else
    AddButton.Enabled := False;
end;

procedure TForm1.AddButtonClick(Sender: TObject);
var
  Conf: TIniFile;
begin
  if (CheckStartStopTime(StartTime.Value, StopTime.Value)) then FillCommand(False, Conf)
  else
    Application.MessageBox('Start Time can not be higher than Stop Timer.', 'Time Error', MB_ICONHAND + MB_OK);
end;


procedure TForm1.FillStatusBar();
begin
  sStatusBar1.Panels.Items[0].Text:= 'Connected:' + BoolToStr(ComPort1.Connected, True);
  sStatusBar1.Panels.Items[1].Text:= 'Port: ' + ComPort1.Port;
end;

procedure TForm1.StartCheckBoxClick(Sender: TObject);
begin
  // 1.Parameter: Path to your Exe-File
  // 2. Parameter: the Title of your Application
  // 3. Set (true) or Unset (false) Autorun
  if (StartCheckBox.Checked) then
    SetAutoStart(ParamStr(0), Form1.Caption, True)
  else
    SetAutoStart(ParamStr(0), Form1.Caption, False)
end;

procedure TForm1.StartEditChange(Sender: TObject);
begin
  SecNull();
end;

procedure TForm1.StatIni(pStart: Boolean);
var
  Conf: TIniFile;
  Directory: String;
  I: Integer;
begin
  Directory:= GetCurrentDir();
  Conf:= TIniFile.Create(Directory + '\' + 'config.ini'); //Directory + Filename
  if (pStart) then
    begin
      if FileExists('config.ini') then
        begin
          //Load Start with Windows / Log /
          StartCheckBox.Checked := Conf.ReadBool('Misc', 'Start With Windows', False);
          LogCheckBox.Checked := Conf.ReadBool('Misc', 'Log', False);
          RunSlider.SliderOn := Conf.ReadBool('Misc', 'Run Button', False);
          //Load Position Form
          Form1.Left := Conf.ReadInteger('Position', 'Left', 0);
          Form1.Top := Conf.ReadInteger('Position', 'Top', 0);
          //Load Setup CPort Config
          ComPort1.Port := Conf.ReadString('Setup', 'Port', '');
          //Load Ini List
          FillCommand(True, Conf);
          FillStatusBar();
        end
      else
        begin
          SetupCPort(True);
        end;
    end
  else
    begin
      //Save Setup CPort Config
      Conf.WriteString('Setup', 'Port', ComPort1.Port);
      //Save Position Form
      Conf.WriteInteger('Position', 'Left', Form1.Left);
      Conf.WriteInteger('Position', 'Top', Form1.Top);
      //Save Auto Start UP / LOG
      Conf.WriteBool('Misc', 'Start With Windows', StartCheckBox.Checked);
      Conf.WriteBool('Misc', 'Run Button', RunSlider.SliderOn);
      Conf.WriteBool('Misc', 'Log', LogCheckBox.Checked);
      //Gambiarra To Save Record
      for I := 0 to 4 do
        begin
          if (Command[I].Name <> '') then
            begin
              Conf.WriteInteger(IntToStr(Command[I].Index), 'Index', Command[I].Index);
              Conf.WriteString(IntToStr(Command[I].Index), 'Name', Command[I].Name);
              Conf.WriteString(IntToStr(Command[I].Index), 'CmdStart', Command[I].CmdStart);
              Conf.WriteTime(IntToStr(Command[I].Index), 'TimeStart', Command[I].TimeStart);
              Conf.WriteString(IntToStr(Command[I].Index), 'CmdStop', Command[I].CmdStop);
              Conf.WriteTime(IntToStr(Command[I].Index), 'TimeStop', Command[I].TimeStop);
              Conf.WriteBool(IntToStr(Command[I].Index), 'Enabled', Command[I].Enabled);
            end;
        end;
      Conf.Free;
    end;
end;

procedure TForm1.StopEditChange(Sender: TObject);
begin
  SecNull();
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  //Send Form to Normal Visualization
  Show;
  WindowState := wsNormal;
  Application.BringToFront();
  TrayIcon1.Visible := False;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SetLength(Command, 5); //Set Array Length (It should be Dynamic)
  SecNull();
  StatIni(True); //True to Read INI File
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  StatIni(False); //False to Save INI File
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  //Send Form to Tray
  if (Self.WindowState = wsMinimized) then
    begin
      Self.Hide;
      TrayIcon1.Visible := True;
    end;
end;

procedure TForm1.LogCheckBoxClick(Sender: TObject);
begin
  //Show or Hide Log Box
  if (LogCheckBox.Checked) then
    begin
      Form1.Height := 320;
      LogMemo.Visible := True;
    end
  else
    begin
      Form1.Height := 220;
      LogMemo.Visible := False;
    end;
end;

procedure TForm1.ResetButtonClick(Sender: TObject);
begin
  SetupCPort(False);
end;

procedure TForm1.NameComboBoxChange(Sender: TObject);
begin
  SecNull();
end;

procedure TForm1.NameComboBoxEnter(Sender: TObject);
begin
  CheckTimer.Enabled := True;
end;

procedure TForm1.NameComboBoxExit(Sender: TObject);
begin
  CheckTimer.Enabled := False;
end;

procedure TForm1.NameComboBoxSelect(Sender: TObject);
var
  I : Integer;
  ItemName: String;
begin
  I := NameComboBox.ItemIndex;
  if (Command[I].Name <> '') then
    begin
      StartEdit.Text := Command[I].CmdStart;
      StopEdit.Text := Command[I].CmdStop;
      StartTime.Value := Command[I].TimeStart;
      StopTime.Value := Command[I].TimeStop;
      EnabledCheckBox.Checked := Command[I].Enabled;
    end;
  //NameComboBox.Enabled := False;
  //AddButton.Caption := 'Edit';
end;

procedure TForm1.RunSliderChanging(Sender: TObject; var CanChange: Boolean);
var
  err: String;
begin
  if (RunSlider.SliderOn = False) then
    begin
      try
        ComPort1.Open;
      finally
        FillStatusBar();
        //RunSlider.BoundLabel.Caption := 'Running';
        RunTimer.Enabled := True;
        GroupBox2.Enabled := False;
        sStatusBar1.Panels.Items[2].Text := 'Script: On';
      end;
    end
  else
    begin
      ComPort1. Close;
      FillStatusBar();
      //RunSlider.BoundLabel.Caption := 'Stopped';
      RunTimer.Enabled := False;
      GroupBox2.Enabled := False;
      RunTimer.Interval := 1000;
      sStatusBar1.Panels.Items[2].Text := 'Script: Off';
    end;
end;

procedure TForm1.RunTimerTimer(Sender: TObject);
var
  Hour: TDateTime;
  I: Integer;
begin
  //Responsable to make script sending at right time the data to ComPort. Interval of 60 seconds.
  if RunTimer.Interval = 1000 then RunTimer.Interval := 60000;
  Hour := Time; //Get Time
  //Loop responsible to check time and determinate the Start/Stop or Send/Send to ComPort and Write it on log.
  for I := 0 to 4 do
    begin
      if (Command[I].Enabled) then
        begin
            if ((Hour >= Command[I].TimeStart) and (Hour <= Command[I].TimeStop) and (Command[I].Running = False)) then
              begin
                Command[I].Running := True;
                ComPort1.WriteStr(Command[I].CmdStart);
                LogMemo.Lines.Add('Start: ' + Command[I].Name + #9 + 'Send: ' + Command[I].CmdStart + TimeToStr(Hour));
              end
            else if ((Hour >= Command[I].TimeStop) and (Command[I].Running = True)) then
              begin
                Command[I].Running := False;
                ComPort1.WriteStr(Command[I].CmdStop);
                LogMemo.Lines.Add('Stop: ' + Command[I].Name + #9 + 'Send: ' + Command[I].CmdStop + TimeToStr(Hour));
              end;
        end;
    end;
end;

end.
