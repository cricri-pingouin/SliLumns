unit COLUMNS;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Menus, StdCtrls, IniFiles;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    mniExit: TMenuItem;
    N2: TMenuItem;
    mniSettings: TMenuItem;
    lblScoreHeader: TLabel;
    lblScore: TLabel;
    lblJewelsHeader: TLabel;
    lblJewels: TLabel;
    imgNext: TImage;
    lblNext: TLabel;
    grpSeparator: TGroupBox;
    lblLevelHeader: TLabel;
    lblLevel: TLabel;
    mniNew: TMenuItem;
    mniAbort: TMenuItem;
    mniPause: TMenuItem;
    mniKeys: TMenuItem;
    mniSep2: TMenuItem;
    mniHighscores: TMenuItem;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    Image6: TImage;
    ImageV1: TImage;
    ImageV2: TImage;
    ImageV3: TImage;
    ImageV4: TImage;
    ImageV5: TImage;
    ImageV6: TImage;
    ImageV7: TImage;
    ImageBlank: TImage;
    mniSep1: TMenuItem;
    function PieceCollided: Boolean;
    procedure CheckLines;
    procedure FormCreate(Sender: TObject);
    procedure mniExitClick(Sender: TObject);
    procedure mniSettingsClick(Sender: TObject);
    procedure MovePieceDown;
    procedure DrawShape(X, Y, ShapeNum: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MovePieceLeft;
    procedure MovePieceRight;
    procedure RotatePiece(Downwards: Boolean);
    procedure NewGame;
    procedure DrawScore;
    procedure TogglePause;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure mniKeysClick(Sender: TObject);
    procedure mniPauseClick(Sender: TObject);
    procedure mniAbortClick(Sender: TObject);
    procedure mniNewClick(Sender: TObject);
    procedure mniHighscoresClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    //Settings
    OptHeight, OptLvlChg, OptSpeed: DWORD;
    OptNext: Boolean;
    //High scores
    HSname: array[1..10] of string;
    HSscore: array[1..10] of DWORD;
    HSjewels: array[1..10] of DWORD;
  end;

const
  ShapeSize = 46; //Size of a brick in pixels
  BoardSizeX = 6; //Width of playing board
  BoardSizeY = 13; //Height of playing board

var
  Form1: TForm1;
  Shape: array[0..6] of^TBitmap;
  Vanish: array[1..7] of^TBitmap;
  CurBlock, NextBlock: array[1..3] of Byte;
  BlockX, BlockY: Integer;
  Board: array[0..BoardSizeX + 1, 0..BoardSizeY + 1] of Byte; //0 and BoardSizeX+1 = fixed border
  //Scoring
  Score, Jewels, Level: DWord;
  LevelTime: DWord; //Timer
  //Flags
  EndGame, Paused: Boolean;

implementation

{$R *.dfm}

uses
  OPTIONS, HIGHSCORES;

function TForm1.PieceCollided: Boolean;
begin
  if Board[BlockX, BlockY + 3] > 0 then
    Result := True
  else
    Result := False;
end;

procedure TForm1.CheckLines;
var
  LinesNum, JewelsNum: Word;
  X, Y, R, TestShape, ScoreMult: Byte;
  TestBoard: array[1..BoardSizeX, 1..BoardSizeY] of Boolean;
  TempVector: array[1..13] of Byte;
begin
  ScoreMult := 0;
  repeat
    JewelsNum := 0;
    LinesNum := 0;
    Inc(ScoreMult);
    //Initialise test board
    for X := 1 to BoardSizeX do
      for Y := 1 to BoardSizeY do
        TestBoard[X, Y] := False;
    //Check for lines
    for X := 1 to BoardSizeX do
      for Y := 1 to BoardSizeY do
      begin
        TestShape := Board[X, Y];
        if (Board[X, Y] > 0) then //Only check lines of actual shapes, not blanks!
        begin
          //Test horizontal
          if (Board[X - 1, Y] = TestShape) and (Board[X + 1, Y] = TestShape) then
          begin
            Inc(LinesNum);
            TestBoard[X - 1, Y] := True;
            TestBoard[X, Y] := True;
            TestBoard[X + 1, Y] := True;
          end;
          //Test vertical
          if (Board[X, Y - 1] = TestShape) and (Board[X, Y + 1] = TestShape) then
          begin
            Inc(LinesNum);
            TestBoard[X, Y - 1] := True;
            TestBoard[X, Y] := True;
            TestBoard[X, Y + 1] := True;
          end;
          //Test 45 degrees
          if (Board[X - 1, Y - 1] = TestShape) and (Board[X + 1, Y + 1] = TestShape) then
          begin
            Inc(LinesNum);
            TestBoard[X - 1, Y - 1] := True;
            TestBoard[X, Y] := True;
            TestBoard[X + 1, Y + 1] := True;
          end;
        //Test -45 degrees
          if (Board[X - 1, Y + 1] = TestShape) and (Board[X + 1, Y - 1] = TestShape) then
          begin
            Inc(LinesNum);
            TestBoard[X - 1, Y + 1] := True;
            TestBoard[X, Y] := True;
            TestBoard[X + 1, Y - 1] := True;
          end;
        end;
      end;
    //No lines formed? Exit
    if LinesNum = 0 then
      Exit;
    //Count jewels
    for X := 1 to BoardSizeX do
      for Y := 1 to BoardSizeY do
        if (TestBoard[X, Y] = True) then
        begin
          Inc(JewelsNum);
          Board[X, Y] := 0;
        end;
    //Update lines completed count
    Inc(Jewels, JewelsNum);
    //Update score depending on number of lines and iteration multiplier
    Inc(Score, LinesNum * 30 * ScoreMult);
    Level := (Jewels div 35) + 1;
    LevelTime := (11 - Level) * (150 - OptSpeed * 10);
    //Animate 7 frames, 40 ms each = 0.28s total
    for R := 1 to 7 do
    begin
      Application.ProcessMessages;
      for Y := 1 to BoardSizeY do
        for X := 1 to BoardSizeX do
          if (TestBoard[X, Y] = True) then
            Form1.Canvas.Draw((X - 1) * ShapeSize, (Y - 1) * ShapeSize, Vanish[R]^);
      Sleep(40);
    end;
    //Remove all scored blocks
    for X := 1 to BoardSizeX do
    begin
      //Initialise temp column
      for Y := 1 to BoardSizeY do
        TempVector[Y] := 0;
      //Populate temp vector with only non-zero values
      R := BoardSizeY + 1;
      for Y := BoardSizeY downto 1 do
        if (Board[X, Y] > 0) then
        begin
          Dec(R);
          TempVector[R] := Board[X, Y];
        end;
      //Copy whole temp column into destination
      for Y := 1 to BoardSizeY do
        Board[X, Y] := TempVector[Y];
    end;
    //ReDraw board
    if not Paused then
      for X := 1 to BoardSizeX do
        for Y := 1 to BoardSizeY do
          DrawShape(X, Y, Board[X, Y]);
  until (LinesNum = 0);
end;

procedure TForm1.DrawShape(X, Y, ShapeNum: Integer);
begin
  Form1.Canvas.Draw((X - 1) * ShapeSize, (Y - 1) * ShapeSize, Shape[ShapeNum]^);
end;

procedure TForm1.NewGame;
var
  X, Y, RC: ShortInt;
  CurrTick, PrevTick: DWORD;
  //High score
  myINI: TINIFile;
  WinnerName: string;
  DRect: TRect;
begin
  Jewels := 0;
  Score := 0;
  EndGame := False;
  Paused := False;
  //Clear board
  //Logically
  for X := 0 to BoardSizeX + 1 do
    for Y := 0 to BoardSizeY + 1 do
      Board[X, Y] := 9; //Use 9 so that it's not any shape to avoid confusion when checking lines
  for X := 1 to BoardSizeX do
    for Y := 1 to BoardSizeY do
      Board[X, Y] := 0;
  //Graphically
  for X := 1 to BoardSizeX do
    for Y := 1 to BoardSizeY do
      DrawShape(X, Y, 0);
  //Add handicap if any
  Randomize;
  if (OptHeight > 0) then
    for Y := BoardSizeY downto (BoardSizeY - OptHeight + 1) do
      for X := 1 to BoardSizeX do
      begin
        RC := Random(6) + 1;
        Board[X, Y] := RC;
        DrawShape(X, Y, RC);
      end;
  //Update menu
  mniNew.Enabled := False;
  mniPause.Enabled := True;
  mniAbort.Enabled := True;
  //Clear image box of previous shape (in case show next disabled)
  DRect := Rect(0, 0, imgNext.Width, imgNext.Height);
  imgNext.Canvas.Rectangle(DRect);
  //Set blocks
  BlockX := 4;
  BlockY := -2; //Set to 0, this will be increased to 1
  for Y := 1 to 3 do
  begin
    CurBlock[Y] := Random(6) + 1;
    NextBlock[Y] := Random(6) + 1;
  end;
  //Initialise score
  Level := 1;
  LevelTime := (11 - Level) * (150 - OptSpeed * 10);
  DrawScore;
  //Initialise timer
  PrevTick := GetTickCount();
  repeat
  begin
    CurrTick := GetTickCount();
    if ((CurrTick - PrevTick) >= LevelTime) and not Paused then
    begin
      PrevTick := CurrTick;
      if (PieceCollided) then
      begin
        if (BlockY <= 0) then
          EndGame := True
        else
        begin
          //Commit current shape to game board
          for Y := 1 to 3 do
            Board[BlockX, BlockY + Y - 1] := CurBlock[Y];
          CheckLines;
          PrevTick := GetTickCount(); //Lots of things might have happened, reset timer for new part
          //Set new shape parameters
          CurBlock := NextBlock;
          BlockX := 4;
          BlockY := -2;
          //Display new shape
          for Y := 1 to 3 do
            DrawShape(BlockX, BlockY + Y - 1, CurBlock[Y]);
          //Choose next shape
          for Y := 1 to 3 do
            NextBlock[Y] := Random(6) + 1;
          //Refresh score/lines/next shape/
          DrawScore;
          //Check if new piece collides on arrival = end game
          if (PieceCollided) then
            EndGame := True;
        end;
      end
      else
        MovePieceDown;
    end
    else
    begin
      Application.ProcessMessages;
      Sleep(15);
    end;
  end;
  until (EndGame) or (Application.Terminated);
  //Game over, fill board
  Application.ProcessMessages;
  for X := 1 to BoardSizeX do
    for Y := 1 to BoardSizeY do
      DrawShape(X, Y, (X + Y) mod 6 + 1);
  //Update menu
  mniNew.Enabled := True;
  mniPause.Enabled := False;
  mniAbort.Enabled := False;
  //Highscore?
  for X := 1 to 10 do
  begin
    if (Score > HSscore[X]) then
    begin
      //Get name
      WinnerName := InputBox('You''re Winner!', 'You placed #' + IntToStr(X) + ' with your score of ' + IntToStr(Score) + '.' + slinebreak + 'Enter your name:', HSname[1]);
      //Shift high scores downwards; If placed 10, skip as we'll simply overwrite last score
      if X < 10 then
        for Y := 10 downto X + 1 do
        begin
          HSname[Y] := HSname[Y - 1];
          HSscore[Y] := HSscore[Y - 1];
          HSjewels[Y] := HSjewels[Y - 1];
        end;
      //Set new high score
      HSname[X] := WinnerName;
      HSscore[X] := Score;
      HSjewels[X] := Jewels;
      //Save high scores to INI file
      myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliLumns.ini');
      for Y := 1 to 10 do
      begin
        myINI.WriteString('HighScores', 'Name' + IntToStr(Y), HSname[Y]);
        myINI.WriteInteger('HighScores', 'Score' + IntToStr(Y), HSscore[Y]);
        myINI.WriteInteger('HighScores', 'Jewels' + IntToStr(Y), HSjewels[Y]);
      end;
      //Close INI file
      myINI.Free;
      //Exit so that we only get 1 high score!
      Exit;
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  myINI: TINIFile;
  i: Byte;
begin
  //Initialise shapes images
  New(Shape[0]);
  Shape[0]^ := ImageBlank.Picture.Bitmap;
  New(Shape[1]);
  Shape[1]^ := Image1.Picture.Bitmap;
  New(Shape[2]);
  Shape[2]^ := Image2.Picture.Bitmap;
  New(Shape[3]);
  Shape[3]^ := Image3.Picture.Bitmap;
  New(Shape[4]);
  Shape[4]^ := Image4.Picture.Bitmap;
  New(Shape[5]);
  Shape[5]^ := Image5.Picture.Bitmap;
  New(Shape[6]);
  Shape[6]^ := Image6.Picture.Bitmap;
  //Initialise vanishing images
  New(Vanish[1]);
  Vanish[1]^ := ImageV1.Picture.Bitmap;
  New(Vanish[2]);
  Vanish[2]^ := ImageV2.Picture.Bitmap;
  New(Vanish[3]);
  Vanish[3]^ := ImageV3.Picture.Bitmap;
  New(Vanish[4]);
  Vanish[4]^ := ImageV4.Picture.Bitmap;
  New(Vanish[5]);
  Vanish[5]^ := ImageV5.Picture.Bitmap;
  New(Vanish[6]);
  Vanish[6]^ := ImageV6.Picture.Bitmap;
  New(Vanish[7]);
  Vanish[7]^ := ImageV7.Picture.Bitmap;
  //Prepare Next image properties
  imgNext.Canvas.Pen.Style := psSolid;
  imgNext.Canvas.Pen.Color := clWhite;
  EndGame := True;
  //Initialise options from INI file
  myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliLumns.ini');
  OptHeight := myINI.ReadInteger('Settings', 'Starting_Height', 0);
  OptLvlChg := myINI.ReadInteger('Settings', 'Level_Change', 35);
  OptSpeed := myINI.ReadInteger('Settings', 'Speed', 10);
  OptNext := myINI.ReadBool('Settings', 'Show_Next', True);
  //Read high scores from INI file
  for i := 1 to 10 do
  begin
    HSname[i] := myINI.ReadString('HighScores', 'Name' + IntToStr(i), 'Nobody');
    HSscore[i] := myINI.ReadInteger('HighScores', 'Score' + IntToStr(i), (11 - i) * 100);
    HSjewels[i] := myINI.ReadInteger('HighScores', 'Jewels' + IntToStr(i), (11 - i) * 10);
  end;
  myINI.Free;
end;

procedure TForm1.MovePieceDown;
var
  Y: Byte;
begin
  DrawShape(BlockX, BlockY, 0); //Only need to clear the top block, bottom 2 will be overwritten
  Inc(BlockY);
  for Y := 1 to 3 do
    DrawShape(BlockX, BlockY + Y - 1, CurBlock[Y]);
end;

procedure TForm1.DrawScore; // and next shape
var
  Y: Word;
begin
  //Draw score on Blended Bitmap  (The background)
  lblScore.Caption := IntToStr(Score);
  lblJewels.Caption := IntToStr(Jewels);
  lblLevel.Caption := IntToStr(Level);
  //Draw new shape
  if (OptNext = True) then
    for Y := 1 to 3 do
      imgNext.Canvas.Draw(0, (Y - 1) * ShapeSize, Shape[NextBlock[Y]]^);
end;

procedure TForm1.MovePieceLeft;
var
  Y: Byte;
begin
  //Is there anything on the board where a square needs to be?
  for Y := 1 to 3 do
    if ((BlockY + Y) > 1) then  //Allow moving when block not fully on screen yet
      if (Board[BlockX - 1, BlockY + Y - 1] > 0) then
        Exit; //Yes: exit
  //Arrived here: it's ok to move left
  //Clear piece from current position
  for Y := 1 to 3 do
    DrawShape(BlockX, BlockY + Y - 1, 0);
  //Decrease X position
  Dec(BlockX);
  //Draw piece in new position
  for Y := 1 to 3 do
    DrawShape(BlockX, BlockY + Y - 1, CurBlock[Y]);
end;

procedure TForm1.MovePieceRight;
var
  Y: Byte;
begin
  //Is there anything on the board where a square needs to be?
  for Y := 1 to 3 do
    if ((BlockY + Y) > 1) then  //Allow moving when block not fully on screen yet
      if (Board[BlockX + 1, BlockY + Y - 1] > 0) then
        Exit; //Yes: exit
  //Arrived here: it's ok to move left
  //Clear piece from current position
  for Y := 1 to 3 do
    DrawShape(BlockX, BlockY + Y - 1, 0);
  //Decrease X position
  Inc(BlockX);
  //Draw piece in new position
  for Y := 1 to 3 do
    DrawShape(BlockX, BlockY + Y - 1, CurBlock[Y]);
end;

procedure TForm1.RotatePiece(Downwards: Boolean);
var
  Y, Temp: Byte;
begin
  if Downwards then
  begin //Downwards
    Temp := CurBlock[3];
    CurBlock[3] := CurBlock[2];
    CurBlock[2] := CurBlock[1];
    CurBlock[1] := Temp;
  end
  else
  begin //Upwards
    Temp := CurBlock[1];
    CurBlock[1] := CurBlock[2];
    CurBlock[2] := CurBlock[3];
    CurBlock[3] := Temp;
  end;
  //Redraw block
  for Y := 1 to 3 do
    DrawShape(BlockX, BlockY + Y - 1, CurBlock[Y]);
end;

procedure TForm1.TogglePause;
var
  X, Y: Byte;
begin
  Paused := not Paused;
  for Y := 1 to BoardSizeY do
    for X := 1 to BoardSizeX do
      if Paused then
        DrawShape(X, Y, (Y mod 6) + 1)
      else
        DrawShape(X, Y, Board[X, Y])
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (EndGame) then
    if (Key = 32) then  //Game over and space: start new game
      NewGame
    else
      Exit; //Else ignore all key presses
  if (Paused) then
    begin
    if (Key = 19) then  //Psused and press Pause: unpause
      TogglePause;
    Exit;
    end;
  case Key of
    17, 101: //Rotate down (Ctrl or num 5)
      RotatePiece(True);
    16, 104: //Rotate up (Shift or num 8)
      RotatePiece(False);
    40, 98: //Down or num 2
      if not PieceCollided then
      begin
        MovePieceDown;
        Inc(Score);
      end;
    39, 102: //Right or num 6
      MovePieceRight;
    37, 100: //Left or num 4
      MovePieceLeft;
    27: //Escape
      EndGame := True;
    19: //Pause
      TogglePause;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TForm1.mniNewClick(Sender: TObject);
begin
  NewGame;
end;

procedure TForm1.mniPauseClick(Sender: TObject);
begin
  TogglePause;
end;

procedure TForm1.mniAbortClick(Sender: TObject);
begin
  EndGame := True;
end;

procedure TForm1.mniExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.mniHighscoresClick(Sender: TObject);
begin
  if Form3.visible = false then
    Form3.show
  else
    Form3.hide;
end;

procedure TForm1.mniKeysClick(Sender: TObject);
begin
  ShowMessage('Left:' + #9 + #9 + 'Left or numpad 4' + sLineBreak + 'Right:' + #9 + #9 + 'Right or numpad 6' + sLineBreak + 'Down:' + #9 + #9 + 'Down or numpad 2' + sLineBreak + 'Rotate down:' + #9 + 'Ctrl or numpad 5' + sLineBreak + 'Rotate up:' + #9 + 'Shift or numpad 8' + sLineBreak + 'Start new game:' + #9 + 'Space' + sLineBreak + 'Pause:' + #9 + #9 + 'Pause' + sLineBreak + 'End game:' + #9 + 'Esc');
end;

procedure TForm1.mniSettingsClick(Sender: TObject);
begin
  if Form2.visible = false then
    Form2.show
  else
    Form2.hide;
end;

end.
