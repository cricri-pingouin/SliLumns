unit OPTIONS;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, COLUMNS, IniFiles;

type
  tForm2 = class(TForm)
    lblHeight: TLabel;
    scrlHeight: TScrollBar;
    chkNext: TCheckBox;
    btnCancel: TButton;
    btnOk: TButton;
    lblHeightV: TLabel;
    lblLevelV: TLabel;
    scrlSpeed: TScrollBar;
    lblSpeed: TLabel;
    scrlLvlChg: TScrollBar;
    lblLvlChg: TLabel;
    lblLvlChgV: TLabel;
    lblSpeedV: TLabel;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure scrlHeightChange(Sender: TObject);
    procedure scrlLvlChgChange(Sender: TObject);
    procedure scrlSpeedChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: tForm2;
implementation

{$R *.dfm}

procedure tForm2.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure tForm2.btnOkClick(Sender: TObject);
var
  myINI: TINIFile;
begin
  Form1.OptHeight := scrlHeight.Position;
  Form1.OptLvlChg := scrlLvlChg.Position;
  Form1.OptSpeed := scrlSpeed.Position;
  Form1.OptNext := chkNext.Checked;
  //Save settings to INI file
  myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliLumns.ini');
  myINI.WriteInteger('Settings', 'Starting_Height', Form1.OptHeight);
  myINI.WriteInteger('Settings', 'Level_Change', Form1.OptLvlChg);
  myINI.WriteInteger('Settings', 'Speed', Form1.OptSpeed);
  myINI.WriteBool('Settings', 'Show_Next', Form1.OptNext);
  myINI.Free;
  Close;
end;

procedure tForm2.FormCreate(Sender: TObject);
begin
  scrlHeight.Position := Form1.OptHeight;
  scrlLvlChg.Position := Form1.OptLvlChg;
  scrlSpeed.Position := Form1.OptSpeed;
  chkNext.Checked := Form1.OptNext;
end;

procedure tForm2.scrlHeightChange(Sender: TObject);
begin
  lblHeightV.Caption := IntToStr(scrlHeight.Position);
end;

procedure tForm2.scrlLvlChgChange(Sender: TObject);
begin
  lblLvlChgV.Caption := IntToStr(scrlLvlChg.Position);
end;

procedure tForm2.scrlSpeedChange(Sender: TObject);
begin
  lblSpeedV.Caption := IntToStr(scrlSpeed.Position);
end;

end.
