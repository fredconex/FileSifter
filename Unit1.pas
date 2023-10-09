unit Unit1;

{$MODE Delphi}

interface

uses
  FileUtil,
  SysUtils,
  Classes,
  Controls,
  Forms,
  Math,
  Dialogs,
  ComCtrls,
  LazFileUtils,
  Menus;

type

  { TForm1 }

  TForm1 = class(TForm)
    FileTree: TTreeView;
    ImageList1: TImageList;
    OpenDialog1: TOpenDialog;
    PopupMenu1: TPopupMenu;
    add_sel: TMenuItem;
    rem_sel: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure add_selClick(Sender: TObject);
    procedure FileTreeDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure rem_selClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
  private
    { Private declarations }
  public
    procedure rec_list_dir(inpath: string; WinAddr1: TTreeNode);
    procedure UpdateList;
    { Public declarations }
  end;

var
  SiftList: TStringList;
  TargetDir: string;
  SourceDir: string;
  Form1: TForm1;

implementation

{$R *.lfm}

const
  SiftListfile = 'FileSifter.txt';

procedure TForm1.rec_list_dir(inpath: string; WinAddr1: TTreeNode);
var
  sr: TSearchRec;
  res: integer;
  TNode: TTreeNode;
  fPath: string;
begin
  res := FindFirst(inpath + '\*.*', faAnyFile, sr);
  while res = 0 do
  begin
    if (Sr.Name <> '.') and (Sr.Name <> '..') then
    begin
      TNode := FileTree.Items.AddChild(WinAddr1, Sr.Name);
      fpath := ExtractRelativePath(ExpandFileName(Sourcedir + '\'), ExpandFileName(inpath + '\' + sr.Name));
      TNode.StateIndex := ifThen(SiftList.IndexOf(fpath) > -1, 2, 1);
      if (sr.Attr and faDirectory) = faDirectory then
        rec_list_dir(inpath + '\' + sr.Name, TNode);
    end;
    res := FindNext(sr);
  end;
  FindClose(sr);
end;

procedure GenList(Nodes: TTreeNodes);
var
  row: integer;
  sName: string;
  N: TTreeNode;
begin
  SiftList.Clear;
  for row := 0 to Nodes.Count - 1 do
  begin
    N := Nodes.Item[row].Parent;
    sName := '';
    while N <> nil do
    begin
      if N.Count = 0 then
        sName := N.Text + sName
      else
        sName := N.Text + '\' + sName;
      N := N.Parent;
    end;
    if Nodes.Item[row].StateIndex = 2 then
      SiftList.add(sName + Nodes.Item[row].Text);
  end;
end;

procedure DisplayHelp;
begin
  WriteLn('Usage:');
  WriteLn('  [executable_name] [options]');
  WriteLn('');
  WriteLn('Options:');
  WriteLn('  -build <path>   Build at the specified path.');
  WriteLn('  -src <path>   Edit from the specified path.');
  WriteLn('');
  WriteLn('Example:');
  WriteLn('  FileSifter.exe -build "C:\target\path"');
  WriteLn('');
end;

procedure TForm1.UpdateList;
begin
  FileTree.Items.BeginUpdate;
  FileTree.Items.Clear;
  rec_list_dir(SourceDir, nil);
  FileTree.Items.EndUpdate;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  row, i: integer;
  fromPath: string;
  toPath: string;
  response: string;
begin
  writeLn('######################################');
  writeLn('  Dreamfoil Creations - FileSifter');
  writeLn('######################################');
  writeLn('');
  if ParamCount = 0 then
    DisplayHelp;
  SiftList := TStringList.Create;
  SourceDir := GetCurrentDir;

  for row := 1 to ParamCount do
  begin
    if (ParamStr(row) = '-src') and (row < ParamCount) then
    begin
      SourceDir := ParamStr(row + 1);
      WriteLn('Source path: ', SourceDir);
    end;
  end;

  if FileExists(SourceDir + '\' + SiftListfile) then
    SiftList.LoadFromFile(SourceDir + '\' + SiftListfile);

  for row := 1 to ParamCount do
  begin
    if (ParamStr(row) = '-build') and (row < ParamCount) then
    begin
      TargetDir := ParamStr(row + 1);
      WriteLn('You requested to build at path: ', TargetDir);
      Write('Are you sure you want to proceed (Y/n)? ');
      ReadLn(response);
      if ((Length(response) > 0) and (LowerCase(response)[1] = 'y')) or (Length(response) = 0) then
      begin
        WriteLn('Building...');

        for i := 0 to SiftList.Count - 1 do
        begin
          fromPath := SourceDir + '\' + SiftList.Strings[i];
          toPath := TargetDir + SiftList.Strings[i];

          if DirPathExists(ExtractFileDir(toPath)) = False then
          begin
            ForceDirectories(ExtractFileDir(toPath));
            WriteLn(PChar('Creating Dir: ' + ExtractFileDir(toPath)));
          end;

          if FileExists(fromPath) then
          begin
            CopyFile(PChar(fromPath), PChar(toPath), False);
            if FileExists(toPath) then
              WriteLn(PChar('[OK] File:' + toPath))
            else
              WriteLn(PChar('[ERROR] File:' + toPath));

          end;
        end;
        WriteLn('Build completed!');
        Application.Terminate;
      end
      else
      begin
        WriteLn('Build cancelled.');
        Application.Terminate;
      end;
    end;
  end;
  UpdateList;
end;

procedure SetNodesTo(StateIndex: integer; Node: TTreeNode);
var
  row: integer;
begin
  Node.StateIndex := StateIndex;

  for row := 0 to Node.Count - 1 do
  begin
    if Node.Items[row].Count > 0 then SetNodesTo(StateIndex, Node.Items[row]);
    Node.Items[row].StateIndex := Node.StateIndex;
  end;
end;

procedure TForm1.FileTreeDblClick(Sender: TObject);
begin
  if FileTree.Selected.StateIndex < 2 then
    FileTree.Selected.StateIndex := 2
  else
    FileTree.Selected.StateIndex := 1;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
  save_filename: string;
begin
  if SourceDir <> '' then
  begin
    GenList(FileTree.TopItem.Owner);
    save_filename := SourceDir + '\' + SiftListfile;
    WriteLn('Saving to: ' + save_filename);
    SiftList.SaveToFile(save_filename);
  end;
  SiftList.Free;
end;

procedure TForm1.add_selClick(Sender: TObject);
var
  row: integer;
begin
  for row := 0 to FileTree.SelectionCount - 1 do
    SetNodesTo(2, FileTree.Selections[row]);
end;

procedure TForm1.rem_selClick(Sender: TObject);
var
  row: integer;
begin
  for row := 0 to FileTree.SelectionCount - 1 do
    SetNodesTo(1, FileTree.Selections[row]);
end;


procedure TForm1.PopupMenu1Popup(Sender: TObject);
begin
end;

end.
