unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ImgList, Grids, ComCtrls, ExtCtrls, StdCtrls, Buttons;

type
  TCellImageState = (icVisible,icHiden,icMarked);
  TCellImage = class
  public
   State: TCellImageState;
   Index: Integer;
   constructor Create(AIndex: Integer);
  end;

  TfrmMain = class(TForm)
    GameField: TStringGrid;
    ImageList: TImageList;
    btnNewGame: TBitBtn;
    ImageList1: TImageList;
    GameTimer: TTimer;
    StatusBar: TStatusBar;
    ResultTable: TMemo;
    Gamer: TEdit;
    sLabel1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure GameFieldDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure GameFieldSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure btnNewGameClick(Sender: TObject);
    procedure GameTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    GameTime: Integer;
    CorrectMovies,WrongMovies: Integer;
    procedure NewGame;
    procedure Shuffle;
    function GameOver: Boolean;
  end;

var
  frmMain: TfrmMain;

implementation
 Uses IniFiles;

{$R *.dfm}

constructor TCellImage.Create(AIndex: Integer);
begin
 State := icHiden;
 Index := AIndex;
end;

procedure TfrmMain.Shuffle;
Var
  Index: Integer;
  Row1,Col1: Integer;
  Row2,Col2: Integer;
  i: Integer;
begin
 for i := 1 to 100
 do begin
    Row1 := Random(GameField.RowCount);
    Col1 := Random(GameField.ColCount);
    Row2 := Random(GameField.RowCount);
    Col2 := Random(GameField.ColCount);
    Index := TCellImage(GameField.Objects[Col1,Row1]).Index;
    TCellImage(GameField.Objects[Col1,Row1]).Index := TCellImage(GameField.Objects[Col2,Row2]).Index;
    TCellImage(GameField.Objects[Col2,Row2]).Index := Index;
    GameField.Repaint;
    end;
end;

procedure TfrmMain.NewGame;
Var
  Col,Row,Index,i: Integer;
  AList: Array of Integer;
  NewSearch: Boolean;
begin
 Randomize;
 SetLength(AList, 0);
 while Length(AList) < 18
 do begin
    Index := Random(ImageList.Count);
    NewSearch := False;
    for i := 0 to High(AList)
    do if AList[i] = Index
       then begin
            NewSearch := True;
            Break;
            end;
    if NewSearch then Continue;
    SetLength(AList,Length(AList)+1);
    AList[High(AList)] := Index;
    end;

 Index := 0;
 for Row := 0 to GameField.RowCount - 1
 do for Col := 0 to (GameField.ColCount shr 1) - 1
    do begin
       GameField.Objects[Col shl 1,Row] := TCellImage.Create(Alist[Index]);
       GameField.Objects[Col shl 1 + 1,Row] := TCellImage.Create(Alist[Index]);
       Inc(Index);
       end;
end;

procedure TfrmMain.btnNewGameClick(Sender: TObject);
begin
 NewGame;
 Shuffle;
 GameTimer.Enabled := True;
 GameTime := 0;
 CorrectMovies := 0;
 WrongMovies := 0;
 GameField.Enabled := True;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
Var IniFile: TIniFile;
    i: Integer;
    FileName: String;
begin
 FileName := Copy(Application.ExeName,1,Length(Application.ExeName)-4)+'.ini';
 IniFile := TIniFile.Create(FileName);
 for i := 0 to ResultTable.Lines.Count - 1
 do IniFile.WriteString('Результаты',IntToStr(i),ResultTable.Lines[i]);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
Var IniFile: TIniFile;
    FileName: String;
begin
 FileName := Copy(Application.ExeName,1,Length(Application.ExeName)-4)+'.ini';
 IniFile := TIniFile.Create(FileName);
 IniFile.ReadSection('Результаты',ResultTable.Lines);
 NewGame;
 Shuffle;
 GameField.Enabled := False;
end;

procedure TfrmMain.GameTimerTimer(Sender: TObject);
Var H, M, S: String;
    T: Integer;
begin
 T := GameTime;
 H := IntToStr(T div 3600);
 Dec(T, T div 3600 * 3600);
 M := IntToStr(T div 60);
 Dec(T, T div 60 * 60);
 S := IntToStr(T mod 60);

 if Length(H) = 1 then H := '0'+ H;
 if Length(M) = 1 then M := '0'+ M;
 if Length(S) = 1 then S := '0'+ S;
 StatusBar.Panels[2].Text := Format('Игровое время: %s:%s:%s',[H,M,S]);
 Inc(GameTime);
end;

procedure TfrmMain.GameFieldDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
 case TCellImage(GameField.Objects[ACol,ARow]).State
 of icHiden: ImageList1.Draw(GameField.Canvas, Rect.Left, Rect.Top, 1, True);
    icVisible: ImageList.Draw(GameField.Canvas, Rect.Left, Rect.Top, TCellImage(GameField.Objects[ACol,ARow]).Index, True);
 end;
end;

procedure TfrmMain.GameFieldSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
Var
  Col,Row: Integer;
begin
 if TCellImage(GameField.Objects[ACol,ARow]).State = icHiden
 then begin
      TCellImage(GameField.Objects[ACol,ARow]).State := icVisible;
      GameField.Repaint;
      Sleep(500);
      for Row := 0 to GameField.RowCount - 1
      do for Col := 0 to GameField.ColCount - 1
         do begin
            if (Row = ARow) and (Col = ACol) then Continue;
            if TCellImage(GameField.Objects[Col,Row]).State = icMarked then Continue;
            if  TCellImage(GameField.Objects[Col,Row]).State = icVisible
            then if TCellImage(GameField.Objects[Col,Row]).Index = TCellImage(GameField.Objects[ACol,ARow]).Index
                 then begin
                      TCellImage(GameField.Objects[Col,Row]).State := icMarked;
                      TCellImage(GameField.Objects[ACol,ARow]).State := icMarked;
                      Inc(CorrectMovies);
                      StatusBar.Panels[1].Text := Format('Верных: %d',[CorrectMovies]);
                      if GameOver
                      then begin
                           GameTimer.Enabled := False;
                           ResultTable.Lines.Add(Format('%s - %s',[Gamer.Text,Copy(StatusBar.Panels[2].Text,16,8)]));
                           end;
                      Exit;
                      end
                 else begin
                      TCellImage(GameField.Objects[Col,Row]).State := icHiden;
                      TCellImage(GameField.Objects[ACol,ARow]).State := icHiden;
                      Inc(WrongMovies);
                      StatusBar.Panels[0].Text := Format('Ходов: %d',[WrongMovies+CorrectMovies]);
                      Exit;
                      end;
            end;
      end;
end;

function TfrmMain.GameOver: Boolean;
Var
  Col,Row: Integer;
begin
 Result := True;
 for Row := 0 to GameField.RowCount - 1
 do for Col := 0 to GameField.ColCount - 1
    do begin
       if TCellImage(GameField.Objects[Col,Row]).State in [icHiden,icVisible]
       then begin
            Result := False;
            Exit;
            end;
       end;
end;

end.
