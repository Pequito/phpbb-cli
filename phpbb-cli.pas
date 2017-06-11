// ====================================================================
// PHPBB Offline Viewer 4 Term.             Copyright 2016-2017 By xqtr
// ====================================================================

{
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; If not, see <http://www.gnu.org/licenses/>.
   
}
{
   _            _   _              ___          _    _       
  /_\  _ _  ___| |_| |_  ___ _ _  |   \ _ _ ___(_)__| |               8888
 / _ \| ' \/ _ \  _| ' \/ -_) '_| | |) | '_/ _ \ / _` |            8 888888 8
/_/ \_\_||_\___/\__|_||_\___|_|   |___/|_| \___/_\__,_|            8888888888
                                                                   8888888888
         DoNt Be aNoTHeR DrOiD fOR tHe SySteM                      88 8888 88
                                                                   8888888888
    .o HaM RaDiO    .o ANSi ARt!       .o MySTiC MoDS              "88||||88"
    .o NeWS         .o WeATheR         .o FiLEs                     ""8888""
    .o GaMeS        .o TeXtFiLeS       .o PrEPardNeSS                  88
    .o TuTors       .o bOOkS/PdFs      .o SuRVaViLiSM          8 8 88888888888
    .o FsxNet       .o SurvNet         .o More...            888 8888][][][888
                                                               8 888888##88888
   TeLNeT : andr01d.zapto.org:9999 [UTC 11:00 - 20:00]         8 8888.####.888
   SySoP  : xqtr                   eMAiL: xqtr.xqtr@gmail.com  8 8888##88##888

}

Program PhpBBCli;

{$mode objfpc}
{$h+}
{$codepage utf-8}

Uses 

{$IFDEF UNIX}{$IFDEF UseCThreads}
cthreads,
  {$ENDIF}cwstring,{$ENDIF}
Classes,
m_Types,
m_Strings,
m_datetime,
m_Input,
m_Output,
m_fileio,
unixtime,
lazutf8,
regexpr,
m_MenuInput,
  { you can add units after this }sqldb, mysql55conn,inifiles;


Const 

  version = '0.10';

  Black           = 00;
  DarkBlue        = 01;
  DarkGreen       = 02;
  DarkCyan        = 03;
  DarkRed         = 04;
  DarkMagenta     = 05;
  Brown           = 06;
  Grey            = 07;
  DarkGrey        = 08;
  LightBlue       = 09;
  LightGreen      = 10;
  LightCyan       = 11;
  LightRed        = 12;
  LightMagenta    = 13;
  Yellow          = 14;
  White           = 15;

  comment_line    = '//';

  //forum table fields
  forum_id = 0;
  parent_id = 1;
  forum_name = 5;
  forum_desc = 6;
  forum_topics_per_page = 19;

  topic_id = 0;
  topic_forum_id = 1;
  topic_title = 6;
  topic_views = 10;
  topic_last_poster_name = 20;

  post_id = 0;
  post_topic_id = 1;
  post_forum_id = 2;
  poster_id = 3;
  post_time = 6;
  post_subject = 14;
  post_text = 15;

  cfg_TextKeyword = 78;
  cfg_TextComment = 8;
  cfg_TextNormal  = 7;
  cfg_TextNumber  = 3;
  cfg_TextHex     = 4;
  cfg_TextCharStr = 12;
  cfg_TextSearch  = 32;
  cfg_TextEmoji   = 14;

  //tdelimeters = [' ',';','-','(',')','.',','];
  tdelimeters = [' '];

Type 


  Titem = Record
    caption: string;
    id: integer;
    desc: string;
    page: byte;
    pos: byte;
    selected: boolean;
    typeof: byte;
  End;

  TConnectionSettings = Record
    ConnectorType      : String;
    Hostname           : String;
    DatabaseName       : String;
    UserName           : String;
    Password           : String;
  End;

  tcurrent = Record
    topic: integer;
    forum: integer;
    post: integer;
    ispost: boolean;
  End;
  tappcolor = Record
    toplinetext: byte;
    toplineback: byte;
    baselinetext: byte;
    baselineback: byte;
    username : byte;
    time : byte;
    percenttext: byte;

    forumtext1: byte;
    forumtext2: byte;
    forumtext3: byte;

    titletext: byte;

    posttext: byte;
    postinfo: byte;
    postsep: byte;
  End;

Var 
  current: tcurrent;
  Screen        : TOutput;
  Image         : TConsoleImageRec;
  Keyboard      : Tinput;
  leave         : boolean;
  greek         : boolean;
  history       : tstringlist;
  history_index : integer;
  database      : string;
  kbbuf         : string;
  ch            : char;
  l             : tstringlist;
  i,e,v         : integer;
  s             : string;
  d             : integer;
  title         : string;
  theme         : tappcolor;
  encoding      : string;
  MyConnection  : TSQLConnector;
  MyTransaction : TSQLTransaction;
  MyQuery       : TSQLQuery;
  ConSet        : TConnectionSettings;
  QuickExit     : Boolean;
  StartDir      : String;
  Keyword       : Array[1..30] Of String[15];




Procedure command(str:String);
forward;
Procedure topline(s:String);
forward;
Procedure showcurrent;
forward;
Procedure sqlexec(sql:String);
forward;
Function gettopictitle(id:integer): string;
forward;


Procedure SetKeywords;
Begin
  Keyword[10] := ':)';
  Keyword[1] := ';)';
  Keyword[2] := ':-)';
  Keyword[3] := ';-)';
  Keyword[4] := ':(';
  Keyword[5] := ':-(';
  Keyword[6] := ':?';
  Keyword[7] := ':]';
  Keyword[8] := ':O';
  Keyword[9] := ':D';
  Keyword[11] := ':LOL:';
End;

Procedure TextBackground(cl:Byte);

Var 
  d: byte;
Begin
  d := Screen.TextAttr;
  d := d Mod 16;
  Screen.TextAttr := d+(cl*16);
End;

Procedure TextColor(cl:Byte);

Var 
  d: byte;
Begin
  d := Screen.TextAttr;
  d := d Div 16;
  Screen.TextAttr := cl+(d*16);
End;

Function ReplaceBBCOdes(S:String): String;

Var 
  S1,S2 : String;
Begin
  s2 := s;
  Result := S2
End;

Function GetQuery : TSQLQuery;

Var MyQuery : TSQLQuery;
Begin
  MyQuery := TSQLQuery.Create(Nil);
  MyQuery.Database := MyConnection;
  MyQuery.Transaction := MyTransaction;
  GetQuery := MyQuery;
End;

Procedure CreateTransaction;
Begin
  MyTransaction := TSQLTransaction.Create(Nil);
  MyTransaction.Database := MyConnection;
End;

Procedure CreateConnection;
Begin
  MyConnection := TSQLConnector.Create(Nil);
  MyConnection.ConnectorType      := ConSet.ConnectorType;
  MyConnection.Hostname           := ConSet.Hostname;
  MyConnection.DatabaseName       := ConSet.DatabaseName;
  MyConnection.UserName           := ConSet.UserName;
  MyConnection.Password           := ConSet.Password;
End;

Function colortobyte(col: String): byte;

Var c: string;
Begin
  c := StrUpper(col);
  If c='YELLOW' Then result := yellow;
  If c='RED' Then result := red;
  If c='GREEN' Then result := green;
  If c='WHITE' Then result := white;
  If c='BLUE' Then result := blue;
  If c='GREY' Then result := grey;
  If c='CYAN' Then result := cyan;
  If c='DARKGRAY' Then result := darkgray;
  If c='MAGENTA' Then result := magenta;
End;

Procedure LoadConfigFile;

Var 
  ini: tinifile;
Begin
  ini := tinifile.create(StartDir+'config.ini');
  With ConSet Do
    Begin
      ConnectorType      := ini.ReadString('Main','Type','MySQL 5.5');
      Hostname           := ini.ReadString('Main','Hostname','127.0.0.1');
      Database           := ini.ReadString('Main','Database','');
      DatabaseName       := database+'_forum';

      UserName           := ini.ReadString('Main','UserName','');
      Password           := ini.ReadString('Main','Password','');
    End;
  Encoding := ini.ReadString('Main','Encoding','utf8');

  Ini.Free;
End;

Procedure CreateConfig;

Var 
  ini: tinifile;
Begin
  ini := tinifile.create('config.ini');
  With Ini Do
    Begin
      WriteString('Main','Type','MySQL 5.5');
      WriteString('Main','Hostname','127.0.0.1');
      WriteString('Main','Database','myphpbbforum');
      WriteString('Main','UserName','myUserName');
      WriteString('Main','Password','myPassword');
      WriteString('Main','Encoding','utf8');
    End;
  Screen.WriteLine('Config file created.');
  Screen.WriteLine('');
End;

Procedure loadsettings;

Var 
  ini: tinifile;
Begin
  With theme Do
    Begin
      toplinetext := white;
      toplineback := blue;
      baselinetext := white;
      baselineback := blue;
      username := cyan;
      time := grey;
      percenttext := white;

      forumtext1 := white;
      forumtext2 := cyan;
      forumtext3 := darkgray;

      titletext := white;

      posttext := darkgray;
      postinfo := white;
      postsep := darkgray;
    End;
  If Not fileexist('theme.ini') Then exit;
  ini := tinifile.create('theme.ini');
  With theme Do
    Begin
      toplinetext := colortobyte(ini.readstring('colors','top_line_text','white'));
      toplineback := colortobyte(ini.readstring('colors','top_line_background','blue'));
      baselinetext := colortobyte(ini.readstring('colors','base_line_text','white'));
      baselineback := colortobyte(ini.readstring('colors','base_line_background','blue'));
      percenttext := colortobyte(ini.readstring('colors','percent','white'));
      forumtext1 := colortobyte(ini.readstring('colors','forum_list_line1','white'));
      forumtext2 := colortobyte(ini.readstring('colors','forum_list_line2','cyan'));
      forumtext3 := colortobyte(ini.readstring('colors','forum_list_line3','darkgray'));
      titletext := colortobyte(ini.readstring('colors','titles_text_color','white'));
      posttext := colortobyte(ini.readstring('colors','normal_text_color','grey'));
      postinfo := colortobyte(ini.readstring('colors','bold_text_color','white'));
      postsep := colortobyte(ini.readstring('colors','line_seperator_color','darkgray'));
    End;
  ini.free;
End;

Procedure WriteHelp;
Begin
  Screen.WriteLine('');
  textcolor(theme.postinfo);
  Screen.WriteLine('      _         ___ ___  __   ___                    ');
  Screen.WriteLine(' _ __| |_  _ __| _ ) _ ) \ \ / (_)_____ __ _____ _ _ ');
  Screen.WriteLine('| ''_ \ '' \| ''_ \ _ \ _ \  \ V /| / -_) V  V / -_) ''_|');
  Screen.WriteLine('| .__/_||_| .__/___/___/   \_/ |_\___|\_/\_/\___|_|  ');
  Screen.WriteLine('|_|       |_|                                        ');
  Screen.WriteLine('                                        Version '+version);
  Screen.WriteLine('');
  textcolor(theme.posttext);
  Screen.WriteLine(' Browse a phpBB forum, offline from a MySql local database');
  Screen.WriteLine(' Usage:');
  Screen.WriteLine('    myphp');
  Screen.WriteLine('');
  Screen.WriteLine(' Options:');
  Screen.WriteLine('    -C  : Create Config File');
  Screen.WriteLine('    -GR : Auto convert Greek to Greeklish');
  Screen.WriteLine('');
  Screen.WriteLine('');
  halt;
End;

Function Center(AnyString: String;c:char; Width: byte): string;
Begin


{repeat
      if length( AnyString ) < Width
         then AnyString:=AnyString+c;
      if length( AnyString ) < Width
         then AnyString:=c+AnyString;
   until length( AnyString ) >= Width;
   Center:=AnyString;}
  Center := StrPadC(anystring,width,c);
End;

Procedure logo;

Var 
  x: integer;
Begin
  x := 100;
  textcolor(theme.postinfo);
  writeln;
  writeln;
  writeln(center('                  888             888888b.  888888b.   ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('                  888             888  "88b 888  "88b  ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('                  888             888  .88P 888  .88P  ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('          88888b. 88888b. 88888b. 8888888K. 8888888K.  ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('          888 "88b888 "88b888 "88b888  "Y88b888  "Y88b ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('          888  888888  888888  888888    888888    888 ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('          888 d88P888  888888 d88P888   d88P888   d88P ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('          88888P" 888  88888888P" 8888888P" 8888888P"  ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('          888             888                          ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('          888             888                          ',' ',screenwidth-1));
  WaitMS(x);
  writeln(center('          888             888                          ',' ',screenwidth-1));
  WaitMS(x);
  writeln;
  WaitMS(x);
  writeln(center('        ___  __  __ _ _                    _                        ',' ',
          screenwidth-1));
  WaitMS(x);
  writeln(center('       /___\/ _|/ _| (_)_ __   ___  /\   /(_) _____      _____ _ __ ',' ',
          screenwidth-1));
  WaitMS(x);
  writeln(center('      //  // |_| |_| | | ''_ \ / _ \ \ \ / / |/ _ \ \ /\ / / _ \ ''__|',' ',
          screenwidth-1));
  WaitMS(x);
  writeln(center('     / \_//|  _|  _| | | | | |  __/  \ V /| |  __/\ V  V /  __/ |   ',' ',
          screenwidth-1));
  WaitMS(x);
  writeln(center('     \___/ |_| |_| |_|_|_| |_|\___|   \_/ |_|\___| \_/\_/ \___|_|   ',' ',
          screenwidth-1));
  WaitMS(x);
  writeln(center('                                                         Version '+version,' ',
          screenwidth-1));
  WaitMS(x);
End;

Procedure defscreen;
Begin
  title := ' ';
  Screen.ClearScreen;
  logo;
  //WaitMS(500);
  Screen.ClearScreen;
End;

Function colortostr(col:byte): string;
Begin
  Case col Of 
    Black          : result := '|00';
    DarkBlue       : result := '|01';
    DarkGreen      : result := '|02';
    DarkCyan       : result := '|03';
    DarkRed        : result := '|04';
    DarkMagenta    : result := '|05';
    Brown          : result := '|06';
    Grey           : result := '|07';
    DarkGrey       : result := '|08';
    LightBlue      : result := '|09';
    LightGreen     : result := '|10';
    LightCyan      : result := '|11';
    LightRed       : result := '|12';
    LightMagenta   : result := '|13';
    Yellow         : result := '|14';
    White          : result := '|15';
  End;
End;

Procedure helpline(s:String);
Begin
  screen.cursorxy(1,screenheight-1);
  textcolor(theme.baselinetext);
  textbackground(theme.baselineback);
  Screen.ClearEOL;
  Screen.WriteStr(center(s,' ',screenwidth));
End;


Function gr2en(text:String): string;

Var q1,q2: integer;
  gr,en,new: string;
  n: char;
  cl: string;
Begin
  result := text;
  If greek=false Then exit;
  new := text;
  gr := 
'αβγδεἐζηθικλμνξοπρσςτυφχψῶωάέήίόύώἀὕἴϊΐϋΰΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΆΈΉΊΌΎΏ»«'
  ;
  en := 'abgdeezh8iklmn3oprsstufxcwwaehiouwayiiiyyABGDEZH8IKLMN3OPRSTYFXCWAEHIOYW""';
  //helpline('Converting to Greek. Please wait...');
  For q1:=1 To utf8length(new) Do
    Begin
      For q2:=1 To utf8length(gr) Do
        Begin
          If utf8copy(new,q1,1)=utf8copy(gr,q2,1) Then
            Begin
              utf8delete(new,q1,1);
              utf8insert(en[q2],new,q1);
              break;
            End;
        End;
    End;
  result := new;
  //helpline('Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.');
End;

{
Function gr2en(text:String): string;

Var q1,q2: integer;
  gr,en,new: string;
  n: char;
  cl: string;
Begin
  result := text;
  If greek=false Then exit;
  new := text;
  gr := 
'αβγδεζηθικλμνξοπρσςτυφχψωάέήίόύώΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΆΈΉΊΌΎΏ'
  ;
  en := 'abgdezh8iklmn3oprsstufxcwaehiouwABGDEZH8IKLMN3OPRSTYFXCWAEHIOYW';
  //helpline('Converting to Greek. Please wait...');
  For q1:=1 To length(new) Do
    Begin
      For q2:=1 To length(gr) Do
        Begin
          If copy(new,q1,1)=copy(gr,q2,1) Then
            Begin
              delete(new,q1,1);
              insert(en[q2],new,q1);
              break;
            End;
        End;
    End;
  result := new;
  //helpline('Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.');
End;
}
Procedure program_exit;
Begin
  history.free;
  l.free;
  MyQuery.Close;
  MyConnection.Close;
  MyQuery.Free;
  MyConnection.Free;
  MyTransaction.Free;
  textcolor(white);
  textbackground(black);
  Screen.ClearScreen;
  Keyboard.free;
  Screen.ClearScreen;
  Screen.Free;
  If fileexist('output.txt') Then fileerase('output.txt');
  halt(0);
End;

Procedure baseline(str:String);
Begin
  textbackground(theme.baselineback);
  textcolor(theme.baselinetext);
  Screen.CursorXY(1,screenheight-1);
  Screen.ClearEOL;
  Screen.WriteStr(center(str,' ',screenwidth));
  Screen.CursorXY(1,screenheight);
  textcolor(theme.titletext);
  textbackground(black);
  Screen.ClearEOL;
  Screen.WriteStr('#> ');
  textcolor(theme.posttext);
End;

Procedure inlinehelp;

Var 
  f: textfile;
Begin
  assign(f,'help.txt');
  Rewrite(f);
  writeln(f,colortostr(theme.titletext));
  writeln(f,'> Commands');
  writeln(f,colortostr(theme.posttext));
  writeln(f,'/exit, /x: exits the program');
  writeln(f,'/index, /i: Goes to board index');
  writeln(f,'/current, /c: Shows current position in forum, in IDs');
  writeln(f,'/post <id>, /p <id>: Display specific post');
  writeln(f,'/topic <id>, /t <id>:Display posts of topic');
  writeln(f,'/forum <id>, /f <id>:Display subforums and topics of specific forum');
  writeln(f,'/save: Save current screen to textfile');
  writeln(f,'/version, /v: show current program version');
  writeln(f,'/members, /m: show all members ordered by username');
  writeln(f,'/members posts, /m posts: show all members orderd by post count');
  writeln(f,'/members id, /m id: show all members ordered by ID');
  writeln(f,'/members last, /m last: show all members ordered by last visit');
  writeln(f,'/user <id>, /u <id>: Show User information ');
  writeln(f,
          '/user <username>,/u <username>: Show User information. Works also with partial username')
  ;
  writeln(f,'help, /help, /h: This screen ');
  writeln(f,'/lasttopics <num>,/lt <num>: Show <num> last topics');
  writeln(f,'/lastposts <num>,/lp <num>: Show <num> last posts');
  writeln(f,'/searchtopics <string>, /st <string>: Search in topic titles');
  writeln(f,'/searchposts <string>, /sp <string>: Search in posts text');
  writeln(f,' ');
  writeln(f,colortostr(theme.titletext)+'> Keys and Shortcuts');
  writeln(f,colortostr(theme.posttext));
  writeln(f,'Up, Down, PgUp, PgDown: Text scroll');
  writeln(f,'Left, Right: Browse command history');
  writeln(f,'Esc: Goes one level up in forum hierarchy');
  closefile(f);
  topline('Available Commands and features...');
End;

Function forumtime(t:integer): string;
Begin
  //result:=formatdatetime('hh:nn DD-MM-YYYY',unixtodatetime(t));
  result := FormatUnixTimeT(t);
End;

Procedure topline(s:String);
Begin
  Screen.CursorXY(1,1);
  textcolor(theme.toplinetext);
  textbackground(theme.toplineback);
  Screen.ClearEOL;
  Screen.WriteStr(stringofchar(' ',screenwidth));
  Screen.CursorXY(1,1);
  Screen.WriteStr(s);
End;

Procedure viewer_pos;

Var q: real;
Begin
  If l.count = 0 Then q := 0
  Else
    Begin
      q := i+screenheight;
      q := ((l.count - q) / l.count) * 100;
      If q<0 Then q := 0;
      If q>100 Then q := 100;
      q := 100-q;
    End;
  Screen.CursorXY(screenwidth-5,screenheight);
  textcolor(theme.percenttext);
  Screen.WriteStr(StrI2S(trunc(q))+'%');
End;

Procedure DrawLineHighlight (Y: Byte; S: String);

Const 
  chNumber = ['0'..'9','.'];
  chIdent  = ['a'..'z','A'..'Z','_'];
  chIdent2 = ['a'..'z','A'..'Z','_','0'..'9'];
  chOpChar = ['+', '-', '/', '*', ':', '='];
  chHexNum = ['a'..'f', 'A'..'F', '0'..'9'];
  chOther  = ['(', ')', ',', '.', '[', ']'];

Type 
  Tokens = (
            tSTRING,
            tCOMMENT,
            tTEXT,
            tNUMBER,
            tKEYWORD,
            tOPCHAR,
            tCHARNUM,
            tHEXNUM,
            tSEARCH,
            tEOL,
            tERROR
           );

Var 
  ResStr    : String = '';
  StrPos    : Byte = 0;
  ScrollPos : Byte = 1;
  Done      : Boolean = False;

Function GetChar : Char;
Begin
  Result := #00;

  While StrPos < Length(S) Do
    Begin
      Inc (StrPos);

      Result := S[StrPos];
      ResStr := ResStr + Result;

      Break;
    End;
End;

Function NextToken : Tokens;

Var 
  Ch    : Char;
  Key   : String;
  Count : Byte;
Begin
  Result := tEOL;
  ResStr := '';
  Key    := '';

  Repeat
    Ch := GetChar;

    If Ch = #00 Then Break;

    If Ch <> #32 Then Key := Key + Ch;

    If Ch In chIdent Then
      Begin
        Result := tTEXT;

        While Ch In chIdent2 Do
          Begin
            Ch  := GetChar;

            If Ch = #00 Then Break;

            Key := Key + Ch;
          End;

        If Ch <> #00 Then
          Begin
            Dec(StrPos);
            //Dec(Key[0]);
            Setlength(key,length(key)-1);
            //Dec(ResStr[0]);
            Setlength(ResStr,length(ResStr)-1);
          End;

        For Count := 1 To High(Keyword) Do
          If StrUpper(Keyword[Count]) = strUpper(Key) Then
            Begin
              Result := tKEYWORD;
              Exit;
            End;


        Exit;
      End
    Else
      If Ch = '''' Then
        Begin
          Result := tSTRING;

          Repeat
            Ch := GetChar;

            Case Ch Of 
              #00  : Exit;
              '''' : If S[StrPos + 1] = '''' Then GetChar
                     Else Exit;
            End;
          Until False;
        End
    Else


      If (Ch = '/') And (S[StrPos + 1] = '/') Then
        Begin
          Result := tCOMMENT;

          Repeat
          Until GetChar = #00;

          Exit;
        End
    Else
      If (Ch = Comment_line)Then
        Begin
          Result := tCOMMENT;
          Repeat
          Until GetChar = #00;
        End
    Else
      If Ch In chNumber Then
        Begin
          Result := tNUMBER;

          While Ch In chNumber Do
            Begin
              Ch := GetChar;

              If Ch = #00 Then Exit;
            End;

          Dec(StrPos);
          //Dec(ResStr[0]);
          Setlength(ResStr,length(ResStr)-1);

          Exit;
        End
    Else
      If Ch In chOpChar Then
        Begin
          Result := tOPCHAR;

          While Ch In chOpChar Do
            Begin
              Ch  := GetChar;

              If Ch = #00 Then Break;

              Key := Key + Ch;
            End;

          If Ch <> #00 Then
            Begin
              Dec(StrPos);
              //Dec(Key[0]);
              //Dec(ResStr[0]);
              Setlength(Key,length(Key)-1);
              Setlength(ResStr,length(ResStr)-1);
            End;

          Exit;
        End
    Else
      If Ch = '#' Then
        Begin
          Result := tCHARNUM;

          Repeat
            Ch := GetChar;

            If Ch = #00 Then Exit;
          Until Not (Ch In chNumber);

          Dec(StrPos);
          // Dec(ResStr[0]);
          Setlength(ResStr,length(ResStr)-1);

          Exit;
        End
    Else
      If Ch = '$' Then
        Begin
          Result := tHEXNUM;

          Repeat
            Ch := GetChar;

            If Ch = #00 Then Exit;
          Until Not (Ch In chNumber);

          Dec(StrPos);
          //Dec(ResStr[0]);
          Setlength(ResStr,length(ResStr)-1);

          Exit;
        End
    Else
      Begin
        Result := tTEXT;
        Exit;
      End;
  Until False;
End;

Procedure WritePart (Str: String);

Var 
  A : Byte;
Begin
  For A := 1 To Length(Str) Do
    Begin
      If ScrollPos < 1 Then
        Inc (ScrollPos)
      Else
        If screen.CursorX < 79 Then screen.WriteChar (Str[A]);
    End;
End;

Begin
  //Console.CursorXY(2, Y);
  screen.CursorXY(1, Y);

  Repeat
    Case NextToken Of 
      tEOL     : Break;
      tNUMBER  : screen.TextAttr := cfg_TextNumber;
      tCOMMENT : screen.TextAttr := cfg_TextComment;
      tKEYWORD : screen.TextAttr := cfg_TextKeyword;
      //tOPCHAR  : screen.TextAttr := cfg_TextKeyword;
      tSEARCH  : screen.TextAttr := cfg_TextSearch;
      tSTRING,
      tCHARNUM : screen.TextAttr := cfg_TextCharStr;
      tHEXNUM  : screen.TextAttr := cfg_TextHex;
      Else
        screen.TextAttr := cfg_TextNormal;
    End;

    WritePart(ResStr);
  Until Done;

  screen.ClearEOL;

End;

Function wrap(ps:String; p:integer): integer;

Var 
  d : integer;
Begin
  For d := p Downto 1 Do
    Begin
      If ps[d] In tdelimeters Then break;
    End;
  result := d;
End;


{
*  p1 := S;
      p2 := S;
      While utf8length(p2) > 80 Do Begin
        wp := wrap(p1,80);
        p1 := utf8copy(p1,1,wp);
        utf8delete(p2,1,wp);
        //Screen.WriteXYPipe (1, Y+e, 7, 79,p1);
* 
* }

Procedure viewer(str: String);

Var 
  x,y,d: integer;
  p1: string;
  p2: string;
  wp : integer;
Begin
  textbackground(black);
  Screen.ClearScreen;
  topline(str);
  baseline('Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.');
  x := Screen.CursorX;
  y := 2;
  Screen.CursorXY(1,2);
  e := 0;
  While (e<=21) And ((i+e)<l.count-1) Do
    Begin
      s := l[i+e];
      If pos('|',s) > 0 Then  Screen.WriteXYPipe (1, Y+e, 7, 79,s)
      Else DrawLineHighlight(y+e,s);
      e := e + 1;
    End;
  //
  viewer_pos;
  Screen.CursorXY(x,screenheight);
End;

Procedure showpost(id:integer);

Var f: textfile;
  pt: string;
  pid: integer;
Begin
  //result:='Post not found... ';
  sqlexec('SELECT post_id,'+database+'_users.username,'+database+

 '_users.user_id,post_postcount,post_time,poster_id,poster_ip,post_subject,post_text,topic_id FROM '
          +database+'_posts LEFT JOIN '+database+'_users ON '+database+'_users.user_id = '+database+
          '_posts.poster_id where post_id='+StrI2S(id));
  Try
    myquery.first;
    pid := myquery.fields.fieldbyname('topic_id').asinteger;
    pt := gettopictitle(pid);
  Except
    helpline('Post not found... Press any key...');
    Keyboard.ReadKey;
End;
sqlexec('SELECT post_id,'+database+'_users.username,'+database+

 '_users.user_id,post_postcount,post_time,poster_id,poster_ip,post_subject,post_text,topic_id FROM '
        +database+'_posts LEFT JOIN '+database+'_users ON '+database+'_users.user_id = '+database+
        '_posts.poster_id where post_id='+StrI2S(id));
Try
  myquery.first;
  assign(f,'output.txt');
  Rewrite(f);
  Write(f,colortostr(theme.postinfo)+'Post: #'+myquery.fields.fieldbyname('post_id').asstring);
  Write(f,' - Time: '+forumtime(myquery.fields.fieldbyname('post_time').asinteger));
  writeln(f,' - User: '+myquery.fields.fieldbyname('username').asstring);
  writeln(f,'Topic: #'+StrI2S(pid)+' '+pt);
  writeln(f,' ');
  writeln(f,'Subject: '+gr2en(myquery.fields.fieldbyname('post_subject').asstring));
  writeln(f,colortostr(theme.postsep)+stringofchar('=',screenwidth-1));
  writeln(f,colortostr(theme.posttext));
  writeln(f,gr2en(myquery.fields.fieldbyname('post_text').asstring),screenwidth-5);


//       writeln(f,wraptext(utf8toansi(myquery.fields.fieldbyname('post_text').asstring),screenwidth));
  closefile(f);
  //end;
Except
  helpline('Post not found... Press any key...');
  Keyboard.ReadKey;
End;

//writeln(' # - ',utf8string(fields.fieldbyname('forum_name').asstring));
//writeln (mId.Value + ' - ' + mFirstName.Value + ', ' +
//  mLastName.Value + ' - ' );
End;

Procedure sqlexec(sql:String);
Begin
  MyQuery := GetQuery;
  MyQuery.SQL.Text := sql;
  MyConnection.Open;
  MyQuery.Open;


{if myquery.active=true then myquery.close;
   myquery.Sql.text := sql;
   myquery.Open;}
End;

Function getforumtitle(id:integer): string;
Begin
  sqlexec('select * from '+database+'_forums where forum_id='+StrI2S(id));
  Try
    myquery.first;
    result := gr2en(myquery.fields.fieldbyname('forum_name').asstring);
  Except
    result := 'Not found forum with id='+StrI2S(id);
End;
End;

Function getusername(id:integer): string;
Begin
  sqlexec('select * from '+database+'_users where user_id='+StrI2S(id));
  Try
    myquery.first;
    result := gr2en(myquery.fields.fieldbyname('username').asstring);
  Except
    result := 'Not found user with id='+StrI2S(id);
End;
End;


Function gettopictitle(id:integer): string;
Begin
  sqlexec('select * from '+database+'_topics where topic_id='+StrI2S(id));
  Try
    myquery.first;
    result := gr2en(myquery.fields.fieldbyname('topic_title').asstring);
  Except
    result := 'Not found topic with id='+StrI2S(id);
End;
End;

Function getposttitle(id:integer): string;
Begin
  sqlexec('select * from '+database+'_posts where post_id='+StrI2S(id));
  Try
    myquery.first;
    result := gr2en(myquery.fields.fieldbyname('post_subject').asstring);
  Except
    result := 'Not found post with id='+StrI2S(id);
End;
End;

Procedure showmembers(typo:byte);

Var 
  f: textfile;
  line: string;
Begin
  Case typo Of 
    1: sqlexec('select * from '+database+'_users order by username asc');
    //username
    2: sqlexec('select * from '+database+'_users order by user_posts asc');
    //posts
    3: sqlexec('select * from '+database+'_users order by user_lastvisit asc');
    //visit
    4: sqlexec('select * from '+database+'_users order by user_id asc');
    //id
  End;

  Try
    myquery.first;
    assign(f,'output.txt');
    reWrite(f);
    writeln(f,colortostr(theme.titletext));
    writeln(f,center('                 _                ',' ',screenwidth-1));
    writeln(f,center(' _ __  ___ _ __ | |__  ___ _ _ ___',' ',screenwidth-1));
    writeln(f,center('| ''  \/ -_) ''  \| ''_ \/ -_) ''_(_-<',' ',screenwidth-1));
    writeln(f,center('|_|_|_\___|_|_|_|_.__/\___|_| /__/',' ',screenwidth-1));
    writeln(f,center('                                  ',' ',screenwidth-1));

    writeln(f,colortostr(theme.postinfo));


//writeln(f,format('  %5s %20s %15s %5s %6s %20s',['ID','Username','Rank','Posts','Gender','Last Visit']));
    writeln(f,'  '+StrPadL('ID',5,' ')+' '+StrPadL('Username',20,' ')+' '+StrPadL('Rank',15,' ')+' '
    +StrPadL('Posts',5,' ')+' '+StrPadL('Gender',6,' ')+' '+StrPadL('Last Visit',20,' '));
    While Not myquery.eof Do
      Begin
        line := '# '+StrPadL(StrI2S(myquery.fields.fieldbyname('user_id').asinteger),5,' ');
        line := line+' '+StrPadL(gr2en(myquery.fields.fieldbyname('username').asstring),20,' ');
        line := line+' '+StrPadL(gr2en(myquery.fields.fieldbyname('user_rank').asstring),15,' ');
        line := line+' '+StrPadL(StrI2S(myquery.fields.fieldbyname('user_posts').asinteger),5,' ');
        line := line+' '+StrPadL(gr2en(myquery.fields.fieldbyname('user_gender').asstring),6,' ');
        line := line+' '+StrPadL(formatunixtimeT(myquery.fields.fieldbyname('user_lastvisit').
                asinteger),20,' ');
        //writeln(f,));
        writeln(f,colortostr(theme.posttext)+line);


//result:='Post: #'+myquery.fields.fieldbyname('post_id').asstring+'- Subject: '+myquery.fields.fieldbyname('post_subject').asstring;

        myquery.next;
        //end;
      End;
    writeln(f,' ');
    closefile(f);
  Except
    helpline('Error... User table maybe missing. Press any key to continue...');
    Keyboard.ReadKey;
End;
End;

Procedure showuser(id:integer);

Var f: textfile;
Begin
  //result:='Viewing topic #'+StrI2S(id);
  sqlexec('select * from '+database+'_users where user_id='+StrI2S(id));
  Try
    myquery.first;
    assign(f,'output.txt');
    Rewrite(f);
    While Not myquery.eof Do
      Begin
        writeln(f,'|15'+'Username');
        writeln(f,'|07'+myquery.fields.fieldbyname('username').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Real Name');
        writeln(f,'|07'+gr2en(myquery.fields.fieldbyname('user_fullname').asstring));
        writeln(f,' ');
        writeln(f,'|15'+'Gender');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_gender').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Birthday');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_birthday').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Country');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_country').asstring);
        writeln(f,' ');
        writeln(f,' ');
        writeln(f,'|15'+'Email');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_email').asstring);
        writeln(f,' ');
        writeln(f,' ');
        writeln(f,'|15'+'ICQ');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_icq').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'AIM');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_aim').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'MSN');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_msnm').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Website');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_website').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'SMS Number');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_sms_number').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Total Posts');
        writeln(f,'|07'+StrI2S(myquery.fields.fieldbyname('user_posts').asinteger));
        writeln(f,' ');
        writeln(f,'|15'+'Member since');
        writeln(f,'|07'+forumtime(myquery.fields.fieldbyname('user_regdate').asinteger));
        writeln(f,' ');
        writeln(f,'|15'+'Last Visit');
        writeln(f,'|07'+forumtime(myquery.fields.fieldbyname('user_lastvisit').asinteger));
        writeln(f,' ');
        writeln(f,'|15'+'Profile Views');
        writeln(f,'|07'+StrI2S(myquery.fields.fieldbyname('profile_views').asinteger));
        writeln(f,' ');
        writeln(f,' ');
        writeln(f,' ');
        myquery.next
        //end;
      End;
    closefile(f);
  Except
    helpline('User not found... Press any key...');
    Keyboard.ReadKey;
End;
End;

Procedure showuser(id:String);
overload;

Var 
  f: textfile;
Begin
  sqlexec('select * from '+database+'_users where username like "%'+strStripB(id,' ')+'%"');
  Try
    myquery.first;
    assign(f,'output.txt');
    Rewrite(f);
    While Not myquery.eof Do
      Begin
        writeln(f,'|15'+'Username');
        writeln(f,'|07'+myquery.fields.fieldbyname('username').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Real Name');
        writeln(f,'|07'+gr2en(myquery.fields.fieldbyname('user_fullname').asstring));
        writeln(f,' ');
        writeln(f,'|15'+'Gender');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_gender').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Birthday');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_birthday').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Country');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_country').asstring);
        writeln(f,' ');
        writeln(f,' ');
        writeln(f,'|15'+'Email');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_email').asstring);
        writeln(f,' ');
        writeln(f,' ');
        writeln(f,'|15'+'ICQ');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_icq').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'AIM');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_aim').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'MSN');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_msnm').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Website');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_website').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'SMS Number');
        writeln(f,'|07'+myquery.fields.fieldbyname('user_sms_number').asstring);
        writeln(f,' ');
        writeln(f,'|15'+'Total Posts');
        writeln(f,'|07'+StrI2S(myquery.fields.fieldbyname('user_posts').asinteger));
        writeln(f,' ');
        writeln(f,'|15'+'Member since');
        writeln(f,'|07'+forumtime(myquery.fields.fieldbyname('user_regdate').asinteger));
        writeln(f,' ');
        writeln(f,'|15'+'Last Visit');
        writeln(f,'|07'+forumtime(myquery.fields.fieldbyname('user_lastvisit').asinteger));
        writeln(f,' ');
        writeln(f,'|15'+'Profile Views');
        writeln(f,'|07'+StrI2S(myquery.fields.fieldbyname('profile_views').asinteger));
        writeln(f,' ');
        writeln(f,stringofchar('=',screenwidth-1));
        writeln(f,' ');
        myquery.next
        //end;
      End;
    closefile(f);
  Except
    helpline('User not found... Press any key...');
    Keyboard.ReadKey;
End;
End;


Procedure lasttopics(count:integer);

Var 
  f: textfile;
Begin
  sqlexec('select * from '+database+'_topics order by topic_id desc limit '+StrI2S(count));
  Try
    myquery.first;
    assign(f,'output.txt');
    Rewrite(f);
    writeln(f,colortostr(theme.titletext));
    writeln(f,center(' _            _        ',' ',screenwidth-1));
    writeln(f,center('| |_ ___ _ __(_)__ ___ ',' ',screenwidth-1));
    writeln(f,center('|  _/ _ \ ''_ \ / _(_-< ',' ',screenwidth-1));
    writeln(f,center(' \__\___/ .__/_\__/__/ ',' ',screenwidth-1));
    writeln(f,center('        |_|            ',' ',screenwidth-1));
    writeln(f,' ');
    writeln(f,center('Last '+StrI2S(count)+' Topics',' ',screenwidth-1));
    While Not myquery.eof Do
      Begin
        //t:=screenwidth-25;


//st:=format('# %5s %15s %ts',[myquery.fields.fieldbyname('topic_id').asstring,myquery.fields.fieldbyname('topic_views').asstring,myquery.fields.fieldbyname('topic_replies').asstring,myquery.fields.fieldbyname('topic_last_poster_name').asstring,forumtime(myquery.fields.fieldbyname('topic_time').asinteger)]);
        Write(f,'# #'+myquery.fields.fieldbyname('topic_id').asstring);
        writeln(f,colortostr(theme.forumtext1)+' '+gr2en(myquery.fields.fieldbyname('topic_title').
        asstring));
        writeln(f,'# '+colortostr(theme.forumtext2)+'Views: '+utf8string(myquery.fields.fieldbyname(
                                                                         'topic_views').asstring),
        ' - Replies: ',utf8string(myquery.fields.fieldbyname('topic_replies').asstring),' - Time: ',
        forumtime(myquery.fields.fieldbyname('topic_time').asinteger));
        writeln(f,'# '+colortostr(theme.forumtext3)+'Created by: '+utf8string(myquery.fields.
                                                                              fieldbyname(

                                                                           'topic_first_poster_name'
        ).asstring),' - Last reply: ',utf8string(myquery.fields.fieldbyname('topic_last_poster_name'
        ).asstring));


//result:='Post: #'+myquery.fields.fieldbyname('post_id').asstring+'- Subject: '+myquery.fields.fieldbyname('post_subject').asstring;
        writeln(f,' ');
        myquery.next;
        //end;
      End;
    closefile(f);
  Except
    helpline('Post not found... Press any key...');
    Keyboard.ReadKey;
End;
End;

Procedure searchtopics(str:String);

Var 
  f: textfile;
Begin
  sqlexec('select * from '+database+'_topics where topic_title like "%'+str+'"');
  Try
    myquery.first;
    assign(f,'output.txt');
    reWrite(f);
    writeln(f,colortostr(theme.titletext));
    writeln(f,center(' _            _        ',' ',screenwidth-1));
    writeln(f,center('| |_ ___ _ __(_)__ ___ ',' ',screenwidth-1));
    writeln(f,center('|  _/ _ \ ''_ \ / _(_-< ',' ',screenwidth-1));
    writeln(f,center(' \__\___/ .__/_\__/__/ ',' ',screenwidth-1));
    writeln(f,center('        |_|            ',' ',screenwidth-1));
    writeln(f,' ');
    writeln(f,center('Results for search term: "'+str+'"',' ',screenwidth-1));
    While Not myquery.eof Do
      Begin
        //t:=screenwidth-25;


//st:=format('# %5s %15s %ts',[myquery.fields.fieldbyname('topic_id').asstring,myquery.fields.fieldbyname('topic_views').asstring,myquery.fields.fieldbyname('topic_replies').asstring,myquery.fields.fieldbyname('topic_last_poster_name').asstring,forumtime(myquery.fields.fieldbyname('topic_time').asinteger)]);
        Write(f,'# #'+myquery.fields.fieldbyname('topic_id').asstring);
        writeln(f,colortostr(theme.forumtext1)+' '+gr2en(myquery.fields.fieldbyname('topic_title').
        asstring));
        writeln(f,'# '+colortostr(theme.forumtext2)+'Views: '+utf8string(myquery.fields.fieldbyname(
                                                                         'topic_views').asstring),
        ' - Replies: ',utf8string(myquery.fields.fieldbyname('topic_replies').asstring),' - Time: ',
        forumtime(myquery.fields.fieldbyname('topic_time').asinteger));
        writeln(f,'# '+colortostr(theme.forumtext3)+'Created by: '+utf8string(myquery.fields.
                                                                              fieldbyname(

                                                                           'topic_first_poster_name'
        ).asstring),' - Last reply: ',utf8string(myquery.fields.fieldbyname('topic_last_poster_name'
        ).asstring));


//result:='Post: #'+myquery.fields.fieldbyname('post_id').asstring+'- Subject: '+myquery.fields.fieldbyname('post_subject').asstring;
        writeln(f,' ');
        myquery.next;
        //end;
      End;
    closefile(f);
  Except
    helpline('Post not found... Press any key...');
    Keyboard.ReadKey;
End;
End;

Procedure searchposts(str:String);

Var 
  f: textfile;
Begin
  sqlexec('SELECT post_id,'+database+'_users.username,'+database+
          '_users.user_id,post_time,poster_id,post_subject FROM '+database+'_posts LEFT JOIN '+
          database+'_users ON '+database+'_users.user_id = '+database+
          '_posts.poster_id where post_text like "%'+str+'%" ORDER BY '+database+
          '_posts.post_time desc');
  Try
    myquery.first;
    assign(f,'output.txt');
    Rewrite(f);
    writeln(f,colortostr(theme.titletext));
    writeln(f,center('              _      ',' ',screenwidth-1));
    writeln(f,center(' _ __  ___ __| |_ ___',' ',screenwidth-1));
    writeln(f,center('| ''_ \/ _ (_-<  _(_-<',' ',screenwidth-1));
    writeln(f,center('| .__/\___/__/\__/__/',' ',screenwidth-1));
    writeln(f,center('|_|                  ',' ',screenwidth-1));
    writeln(f,' ');
    writeln(f,center('Results for search term: "'+str+'"',' ',screenwidth-1));
    While Not myquery.eof Do
      Begin
        //t:=screenwidth-25;


//st:=format('# %5s %15s %ts',[myquery.fields.fieldbyname('topic_id').asstring,myquery.fields.fieldbyname('topic_views').asstring,myquery.fields.fieldbyname('topic_replies').asstring,myquery.fields.fieldbyname('topic_last_poster_name').asstring,forumtime(myquery.fields.fieldbyname('topic_time').asinteger)]);
        Write(f,'# #'+myquery.fields.fieldbyname('post_id').asstring);
        writeln(f,colortostr(theme.forumtext1)+' '+myquery.fields.fieldbyname('post_subject').
        asstring);
        writeln(f,'# '+colortostr(theme.forumtext2)+'Created by: '+utf8string(myquery.fields.
                                                                              fieldbyname('username'
        ).asstring),' - Time: ',forumtime(myquery.fields.fieldbyname('post_time').asinteger));


//result:='Post: #'+myquery.fields.fieldbyname('post_id').asstring+'- Subject: '+myquery.fields.fieldbyname('post_subject').asstring;
        writeln(f,' ');
        myquery.next;
        //end;
      End;
    closefile(f);
  Except
    helpline('Post not found... Press any key...');
    Keyboard.ReadKey;
End;
End;


Procedure lastposts(count:integer);

Var 
  f: textfile;
Begin
  //sqlexec('select * from '+database+'_posts order by post_id desc limit '+StrI2S(count));
  sqlexec('SELECT post_id,'+database+'_users.username,'+database+
          '_users.user_id,post_time,poster_id,post_subject FROM '+database+'_posts LEFT JOIN '+
          database+'_users ON '+database+'_users.user_id = '+database+'_posts.poster_id ORDER BY '+
          database+'_posts.post_time desc limit '+StrI2S(count));
  Try
    myquery.first;
    assign(f,'output.txt');
    Rewrite(f);
    writeln(f,colortostr(theme.titletext));
    writeln(f,center('              _      ',' ',screenwidth-1));
    writeln(f,center(' _ __  ___ __| |_ ___',' ',screenwidth-1));
    writeln(f,center('| ''_ \/ _ (_-<  _(_-<',' ',screenwidth-1));
    writeln(f,center('| .__/\___/__/\__/__/',' ',screenwidth-1));
    writeln(f,center('|_|                  ',' ',screenwidth-1));
    writeln(f,' ');
    writeln(f,center('Last '+StrI2S(count)+' Posts',' ',screenwidth-1));
    While Not myquery.eof Do
      Begin
        //t:=screenwidth-25;


//st:=format('# %5s %15s %ts',[myquery.fields.fieldbyname('topic_id').asstring,myquery.fields.fieldbyname('topic_views').asstring,myquery.fields.fieldbyname('topic_replies').asstring,myquery.fields.fieldbyname('topic_last_poster_name').asstring,forumtime(myquery.fields.fieldbyname('topic_time').asinteger)]);
        Write(f,'# #'+myquery.fields.fieldbyname('post_id').asstring);
        writeln(f,colortostr(theme.forumtext1)+' '+gr2en(myquery.fields.fieldbyname('post_subject').
        asstring));
        writeln(f,'# '+colortostr(theme.forumtext2)+'Created by: '+utf8string(myquery.fields.
                                                                              fieldbyname('username'
        ).asstring),' - Time: ',forumtime(myquery.fields.fieldbyname('post_time').asinteger));


//result:='Post: #'+myquery.fields.fieldbyname('post_id').asstring+'- Subject: '+myquery.fields.fieldbyname('post_subject').asstring;
        writeln(f,' ');
        myquery.next;
        //end;
      End;
    closefile(f);
  Except
    helpline('Post not found... Press any key...');
    Keyboard.ReadKey;
End;
End;

Procedure showforum(id:integer);

Var 
  f: textfile;
  t: integer;
  st: string;
Begin
  //result:='Viewing forum #'+StrI2S(id);
  sqlexec('select * from '+database+'_forums where parent_id='+StrI2S(id)+' order by forum_id asc');
  Try
    myquery.first;
    //if myquery.recordcount>1 then begin

    //assign(f,extractfilepath(paramstr(0))+'output.txt');
    assign(f,'output.txt');
    reWrite(f);
    writeln(f,colortostr(theme.titletext));
    writeln(f,center('   __                        ',' ',screenwidth-1));
    writeln(f,center('  / _|___ _ _ _  _ _ __  ___ ',' ',screenwidth-1));
    writeln(f,center('|  _/ _ \ ''_| || | ''  \(_-<',' ',screenwidth-1));
    writeln(f,center('|_| \___/_|  \_,_|_|_|_/__/',' ',screenwidth-1));
    writeln(f,' ');

    writeln(f,'');
    While Not myquery.eof Do
      Begin
        Write(f,'#'+myquery.fields.fieldbyname('forum_id').asstring+' - ');
        writeln(f,colortostr(theme.forumtext1)+gr2en(myquery.fields.fieldbyname('forum_name').
        asstring));
        writeln(f,colortostr(theme.forumtext2)+'Description: '+gr2en(myquery.fields.fieldbyname(
                                                                     'forum_desc').asstring));
        writeln(f,colortostr(theme.forumtext3)+'Topics: '+StrI2S(myquery.fields.fieldbyname(
                                                                 'forum_topics').asinteger),
        ' - Posts: ',StrI2S(myquery.fields.fieldbyname('forum_posts').asinteger),' - Last Poster: ',
        gr2en(myquery.fields.fieldbyname('forum_last_poster_name').asstring));


//result:='Post: #'+myquery.fields.fieldbyname('post_id').asstring+'- Subject: '+myquery.fields.fieldbyname('post_subject').asstring;
        writeln(f,' ');
        myquery.next;
        //end;
      End;
    closefile(f);
  Except
    helpline('Post not found... Press any key...');
    Keyboard.ReadKey;
End;
If myquery.active=true Then myquery.close;
myquery.Sql.text := 'select * from '+database+'_topics where forum_id='+StrI2S(id)+
                    ' order by topic_time desc';
myquery.Open;
Try
  myquery.first;
  //if myquery.recordcount>1 then begin

  //assign(f,extractfilepath(paramstr(0))+'output.txt');
  assign(f,'output.txt');
  append(f);
  writeln(f,colortostr(theme.titletext));
  writeln(f,center(' _            _        ',' ',screenwidth-1));
  writeln(f,center('| |_ ___ _ __(_)__ ___ ',' ',screenwidth-1));
  writeln(f,center('|  _/ _ \ ''_ \ / _(_-< ',' ',screenwidth-1));
  writeln(f,center(' \__\___/ .__/_\__/__/ ',' ',screenwidth-1));
  writeln(f,center('        |_|            ',' ',screenwidth-1));
  writeln(f,' ');
  writeln(f,'');
  While Not myquery.eof Do
    Begin
      t := myquery.fields.fieldbyname('topic_time').asinteger;
      st := forumtime(t);
      Write(f,'# #'+myquery.fields.fieldbyname('topic_id').asstring+' - ');
      writeln(f,colortostr(theme.forumtext1)+gr2en(myquery.fields.fieldbyname('topic_title').
      asstring));
      writeln(f,'# '+colortostr(theme.forumtext2)+'Views: '+utf8string(myquery.fields.fieldbyname(
                                                                       'topic_views').asstring),
      ' - Replies: ',utf8string(myquery.fields.fieldbyname('topic_replies').asstring),' - Time: ',st
      );
      writeln(f,'# '+colortostr(theme.forumtext3)+'Created by: '+gr2en(myquery.fields.fieldbyname(
                                                                       'topic_first_poster_name').
      asstring),' - Last reply: ',gr2en(myquery.fields.fieldbyname('topic_last_poster_name').
      asstring));


//result:='Post: #'+myquery.fields.fieldbyname('post_id').asstring+'- Subject: '+myquery.fields.fieldbyname('post_subject').asstring;
      writeln(f,' ');
      myquery.next;
      //end;
    End;
  closefile(f);
Except
  helpline('Post not found... Press any key...');
  Keyboard.ReadKey;
End;
//writeln(' # - ',utf8string(fields.fieldbyname('forum_name').asstring));
//writeln (mId.Value + ' - ' + mFirstName.Value + ', ' +
//  mLastName.Value + ' - ' );
current.ispost := false;
current.post := 0;
current.topic := 0;
current.forum := id;
End;

Procedure showtopic(id:integer);

Var 
  f: textfile;
  t: integer;
  st: string;
  l1,l2: string;
  w : integer;
Begin

  screen.clearscreen;
  screen.Writexy(1,12,15,StrPadC('Please Wait...',80,' '));

  sqlexec('SELECT post_id,'+database+'_users.username,'+database+

 '_users.user_id,post_postcount,post_time,poster_id,poster_ip,post_subject,post_text,topic_id FROM '
          +database+'_posts LEFT JOIN '+database+'_users ON '+database+'_users.user_id = '+database+
          '_posts.poster_id where topic_id='+StrI2S(id)+' ORDER BY '+database+'_posts.post_time');
  Try
    myquery.first;
    //if myquery.recordcount>1 then begin

    //assign(f,extractfilepath(paramstr(0))+'output.txt');
    assign(f,'output.txt');
    reWrite(f);

    While Not myquery.eof Do
      Begin
        writeln(f,colortostr(theme.postsep)+stringofchar('=',screenwidth-2));
        t := myquery.fields.fieldbyname('post_time').asinteger;
        st := forumtime(t);
        Write(f,colortostr(theme.postinfo)+myquery.fields.fieldbyname('post_id').asstring+' - ');
        writeln(f,gr2en(myquery.fields.fieldbyname('post_subject').asstring));
        writeln(f,colortostr(theme.postinfo)+'User: '+colortostr(theme.username)+gr2en(myquery.
                                                                                       fields.
                                                                                       fieldbyname(
                                                                                       'username').
        asstring)+colortostr(theme.postinfo)+
        ' - Time: '+colortostr(theme.time)+st);
        writeln(f,colortostr(theme.postsep)+stringofchar('=',screenwidth-2));
        writeln(f,colortostr(theme.posttext));
        st := gr2en(replacebbcodes(myquery.fields.fieldbyname('post_text').asstring));
        If utf8length(st)>79 Then
          Begin
            l2 := st;
            While utf8length(l2) > 79 Do
              Begin
                w := wrap(l2,79);
                l1 := copy(l2,1,w);
                delete(l2,1,w);
                writeln(f,l1);
              End;
            writeln(f,l2);
          End
        Else
          writeln(f,st);


//result:='Post: #'+myquery.fields.fieldbyname('post_id').asstring+'- Subject: '+myquery.fields.fieldbyname('post_subject').asstring;
        writeln(f,' ');
        myquery.next;
        //end;
      End;
    closefile(f);
  Except
    helpline('Post not found... Press any key...');
    Keyboard.ReadKey;
End;
current.ispost := false;
current.post := 0;
current.topic := id;
End;

Procedure savetofile;

Var filename: string;
Begin
  helpline('Enter filename. Leave empty to cancel.');
  textbackground(black);
  Screen.CursorXY(1,screenheight);
  Screen.WriteStr('#> Filename: ');
  Screen.CursorXY(14,screenheight);
  read(filename);
  If strStripB(filename,' ')='' Then baseline(

                       'Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.'
    )
  Else
    Begin
      filecopy('output.txt',filename);
    End;
  showcurrent;
End;

Procedure index;
Begin
  title := '[] Board Index';
  showforum(0);
  l.clear;
  l.loadfromfile('output.txt');
  i := 0;
  current.topic := 0;
  current.forum := 0;
  current.post := 0;
  viewer('Viewing forum #'+s);
  topline('[] Board Index');
End;

Procedure back;

Var c: char;
Begin
  If current.ispost Then
    Begin
      current.ispost := false;
      current.post := 0;
      command('/topic '+StrI2S(current.topic));
      exit;
    End;
  If current.topic>0 Then
    Begin
      current.ispost := false;
      current.post := 0;
      current.topic := 0;
      command('/forum '+StrI2S(current.forum));
      exit;
    End;
  If current.forum>0 Then
    Begin
      current.ispost := false;
      current.post := 0;
      current.topic := 0;
      current.forum := 0;
      index;
      exit;
    End;
  helpline('Are you sure? (y/n)');
  Screen.CursorXY(4,screenheight);
  c := Keyboard.ReadKey;
  If StrUpper(c)='Y' Then
    Begin
      program_exit;
    End;
  helpline('Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.');
  textcolor(theme.posttext);
End;

Procedure command(str:String);

Var 
  s: string;
  c: char;
  i1: integer;
  found: boolean;
  id,error: integer;
Begin
  found := false;
  s := StrUpper(str);
  If (pos('HELP',s)>0) Or (pos('/H',s)>0) Then
    Begin
      inlinehelp;
      title := 'Help - Commands and keyboard keys.';
      l.clear;
      i := 0;
      l.loadfromfile('help.txt');
      viewer(title);
      helpline('Press any key to continue...');
      Keyboard.ReadKey;
      textbackground(black);
      command('/i');
      found := true;
    End;
  If (pos('/SAVE',s)>0) Then
    Begin
      savetofile;
      found := true;
    End;
  If (pos('/BACK',s)>0) Or (pos('/B',s)>0) Then
    Begin
      back;
      found := true;
    End;
  If (pos('/VERSION',s)>0) Or (pos('/V',s)>0) Then
    Begin
      For i1:=2 To screenheight-2 Do
        Begin
          Screen.CursorXY(1,i1);
          Screen.ClearEOL;
        End;
      Screen.CursorXY(1,2);
      logo;
      helpline('Press any key to continue...');
      Keyboard.ReadKey;
      showcurrent;
      found := true;
    End;
  If (pos('/INDEX',s)>0) Or (pos('/I',s)>0) Then
    Begin
      index;
      found := true;
      Screen.CursorXY(4,screenheight);
    End;
  If (pos('/CURRENT',s)>0) Or (pos('/C',s)>0) Then
    Begin
      helpline('Forum: '+StrI2S(current.forum)+' - Topic: '+StrI2S(current.topic)+' - Post: '+StrI2S
      (current.post)+'. Press key to continue...');
      Keyboard.ReadKey;
      found := true;
    End;
  If (pos('/SEARCHPOSTS',s)>0) Or (pos('/SP',s)>0) Then
    Begin
      found := true;
      delete(s,pos('/SEARCHPOSTS',s),12);
      delete(s,pos('/SP',s),3);
      s := strStripB(s,' ');
      Try
        title := 'Search Results ';
        searchposts(s);
        l.clear;
        l.loadfromfile('output.txt');
        i := 0;
        viewer(title);
      Except
        helpline('Error on command. Make sure you typed it correct. Any key to continue...');
        Keyboard.ReadKey;
    End;
End;
If (pos('/LASTPOSTS',s)>0) Or (pos('/LP',s)>0) Then
  Begin
    found := true;
    delete(s,pos('/LASTPOSTS',s),10);
    delete(s,pos('/LP',s),3);
    s := strStripB(s,' ');
    val(s,id,error);
    If error=0 Then
      Begin
        Try
          title := 'Last '+s+' Posts';
          lastposts(id);
          l.clear;
          l.loadfromfile('output.txt');
          i := 0;
          viewer(title);
        Except
          helpline('Error on command. Make sure you typed it correct. Any key to continue...');
          Keyboard.ReadKey;
      End;
  End;
End;
If (pos('/POST',s)>0) Or (pos('/P',s)>0) Then
  Begin
    found := true;
    delete(s,pos('/POST',s),5);
    delete(s,pos('/P',s),2);
    strStripB(s,' ');
    val(s,id,error);
    If error=0 Then
      Begin
        Try
          title := getposttitle(id);
          showpost(id);
          l.clear;
          l.loadfromfile('output.txt');
          i := 0;
          viewer(title);
        Except
          helpline('Error on command. Make sure you typed it correct. Any key to continue...');
          Keyboard.ReadKey;
      End;
  End;
End;
If (pos('/FORUM',s)>0) Or (pos('/F',s)>0) Then
  Begin
    found := true;
    delete(s,pos('/FORUM',s),6);
    delete(s,pos('/F',s),2);
    strStripB(s,' ');
    val(s,id,error);
    If error=0 Then
      Begin
        Try
          title := getforumtitle(id);
          showforum(id);
          l.clear;
          l.loadfromfile('output.txt');
          i := 0;
          viewer(title);
        Except
          helpline('Error on command. Make sure you typed it correct. Any key to continue...');
          Keyboard.ReadKey;
      End;
  End;
End;
If (pos('/USER',s)>0) Or (pos('/U',s)>0) Then
  Begin
    found := true;
    delete(s,pos('/USER',s),5);
    delete(s,pos('/U',s),2);
    strStripB(s,' ');
    val(s,id,error);
    If error=0 Then
      Begin
        Try
          title := 'Information about user: '+getusername(id);
          showuser(id);
          l.clear;
          l.loadfromfile('output.txt');
          i := 0;
          viewer(title);
        Except
          helpline('Error on command. Make sure you typed it correct. Any key to continue...');
          Keyboard.ReadKey;
      End;
  End
Else
  Begin
    Try
      title := 'Information about user: '+s;
      showuser(s);
      l.clear;
      l.loadfromfile('output.txt');
      i := 0;
      viewer(title);
    Except
      helpline('Error on command. Make sure you typed it correct. Any key to continue...');
      Keyboard.ReadKey;
  End;
End;
End;

If (pos('/LASTTOPICS',s)>0) Or (pos('/LT',s)>0) Then
  Begin
    found := true;
    delete(s,pos('/LASTTOPICS',s),11);
    delete(s,pos('/LT',s),3);
    s := strStripB(s,' ');
    val(s,id,error);
    If error=0 Then
      Begin
        Try
          title := 'Last '+s+' Topics ';
          lasttopics(id);
          l.clear;
          l.loadfromfile('output.txt');
          i := 0;
          viewer(title);
        Except
          helpline('Error on command. Make sure you typed it correct. Any key to continue...');
          Keyboard.ReadKey;
      End;
  End;
End;
If (pos('/SEARCHTOPICS',s)>0) Or (pos('/ST',s)>0) Then
  Begin
    found := true;
    delete(s,pos('/SEARCHTOPICS',s),13);
    delete(s,pos('/ST',s),3);
    s := strStripB(s,' ');
    Try
      title := 'Search Results ';
      searchtopics(s);
      l.clear;
      l.loadfromfile('output.txt');
      i := 0;
      viewer(title);
    Except
      helpline('Error on command. Make sure you typed it correct. Any key to continue...');
      Keyboard.ReadKey;
  End;
End;
If (pos('/TOPIC',s)>0) Or (pos('/T',s)>0) Then
  Begin
    found := true;
    delete(s,pos('/TOPIC',s),6);
    delete(s,pos('/T',s),2);
    strStripB(s,' ');
    val(s,id,error);
    If error=0 Then
      Begin
        Try
          title := gettopictitle(id)+' ['+StrI2S(id)+']';
          showtopic(id);
          l.clear;
          l.loadfromfile('output.txt');
          i := 0;
          viewer(title);
        Except
          helpline('Error on command. Make sure you typed it correct. Any key to continue...');
          Keyboard.ReadKey;
      End;
  End;
End;

If (pos('/MEMBERS ID',s)>0) Or (pos('/M ID',s)>0) Then
  Begin
    found := true;
    title := 'Members ordered by ID';
    showmembers(4);
    l.clear;
    l.loadfromfile('output.txt');
    i := 0;
    viewer(title);

  End;
If (pos('/MEMBERS POSTS',s)>0) Or (pos('/M POSTS',s)>0) Then
  Begin
    found := true;
    title := 'Members ordered by Post count';
    showmembers(2);
    l.clear;
    l.loadfromfile('output.txt');
    i := 0;
    viewer(title);

  End;
If (pos('/MEMBERS LAST',s)>0) Or (pos('/M LAST',s)>0) Then
  Begin
    found := true;
    title := 'Members ordered by Last Visit';
    showmembers(3);
    l.clear;
    l.loadfromfile('output.txt');
    i := 0;
    viewer(title);

  End;
If (pos('/MEMBERS',s)>0) Or (pos('/M',s)>0) Then
  Begin
    If found=true Then exit
    Else found := true;
    title := 'Members ordered by Username';
    showmembers(1);
    l.clear;
    l.loadfromfile('output.txt');
    i := 0;
    viewer(title);

  End;

If (pos('/EXIT',s)>0) Or (pos('/X',s)>0) Then
  Begin
    found := true;
    helpline('Are you sure? (y/n)');
    Screen.CursorXY(4,screenheight);
    c := Keyboard.ReadKey;
    If StrUpper(c)='Y' Then
      Begin
        program_exit;
      End;
    helpline('Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.');
    textcolor(theme.posttext);
  End;
If found=false Then baseline('Command not found...');

textcolor(theme.posttext);
textbackground(black);
Screen.CursorXY(4,screenheight);

End;

Procedure showcurrent;
Begin
  If current.ispost Then
    Begin
      command('post '+StrI2S(current.post));
      exit;
    End;
  If current.topic>0 Then
    Begin
      current.post := 0;
      current.ispost := false;
      showtopic(current.topic);
      exit;
    End;
  If current.forum>=0 Then
    Begin
      current.post := 0;
      current.ispost := false;
      current.topic := 0;
      command('forum '+StrI2S(current.forum));
    End;

End;

Begin
  QuickExit := False;
  Screen := TOutput.Create(True);
  Keyboard := Tinput.create;
  StartDir := JustPath(Paramstr(0));
  If Not FileExist(StartDir+'config.ini') Then
    Begin
      Screen.WriteLine('');
      Screen.WriteLine('No config file, found. Type msphp -c to create one.');
      Screen.WriteLine('');
      QuickExit := True;
    End
  Else
    Begin
      LoadConfigFile;
      If ConSet.UserName='' Then
        Begin
          Screen.WriteLine('No UserName in Config File.');
          Screen.WriteLine('');
          QuickExit := True;
        End;
      If ConSet.DatabaseName='' Then
        Begin
          Screen.WriteLine('No Database name in Config File..');
          Screen.WriteLine('');
          QuickExit := True;
        End;
    End;

  For d:=0 To paramcount Do
    Begin
      Case StrUpper(paramstr(d)) Of 
        '-GR','--GR': greek := true;
        '-C','--C':
                    Begin
                      CreateConfig;
                      QuickExit := True;
                    End;
        '-h','--h','/?','-?','--help','-help':
                                               Begin
                                                 WriteHelp;
                                                 QuickExit := True;
                                               End;
        Else greek := false;
      End;
    End;

  If QuickExit Then
    Begin
      Screen.Free;
      Keyboard.Free;
      Exit;
    End;

  Screen.SetWindowTitle('PhpBB Viewer');
  loadsettings;
  defscreen;
  kbbuf := '';
  leave := false;

  CreateConnection;
  CreateTransaction;
  MyQuery := GetQuery;

  MyConnection.Open;
  MyQuery.SQL.Text := 'select * from '+database+'_users';
  MyQuery.Open;

  history := tstringlist.create;
  history_index := 0;
  l := tstringlist.create;
  current.topic := 0;
  current.forum := 0;
  current.post := 0;
  current.ispost := false;

  Try
    //     PrimaryKey := 'Id';
    MyQuery.close;
    //sql.text:='PRAGMA encoding = "'+encoding+'"';
    //execsql;
    MyQuery.sql.text := 'SET names '''+encoding+'''';
    MyQuery.execsql;
    MyQuery.sql.text := 'SET CHARACTER SET '''+encoding+'''';
    MyQuery.execsql;
    MyQuery.Sql.text := 'select * from '+database+'_forums where parent_id=0';
    MyQuery.Open;


    i := 0;
    d := 0;
    MyQuery.First;
    While Not MyQuery.Eof Do
      Begin

        MyQuery.Next;
        d := d+1;
      End;

  Finally

End;
//writeln(screenwidth,' ',screenheight);
//l.loadfromfile('phpbb2sqlite.pas');
//viewer('asd');
index;
//viewer('Viewing forum #'+s);
topline('[] Board Index');
viewer('[] Board Index');
baseline('Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.');
Repeat
  ch := Keyboard.ReadKey;
  //writeln(ord(ch));
  Case ch Of 
    '[',#75:
             Begin
               If (history_index>0) And (history.count>0) Then
                 Begin
                   history_index := history_index-1;
                   baseline(

                       'Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.'
                   );
                   Screen.WriteStr(history[history_index]);
                   kbbuf := history[history_index];
                 End;
             End;
    ']',#77:
             Begin
               If (history_index<history.count-1) And (history.count>0) Then
                 Begin
                   history_index := history_index+1;
                   baseline(

                       'Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.'
                   );
                   Screen.WriteStr(history[history_index]);
                   kbbuf := history[history_index];
                 End;
             End;
    #8:
        Begin
          Screen.CursorXY(4,screenheight);
          Screen.WriteStr(stringofchar(' ',length(kbbuf)));
          delete(kbbuf,length(kbbuf),1);
          Screen.CursorXY(4,screenheight);
          Screen.WriteStr(kbbuf);
        End;
    #72:
         Begin
           If i-1<0 Then i := 0
           Else i := i-1;
           viewer_pos;
           viewer(title);
         End;
    //Up key
    #80:
         Begin
           If i+screenheight-3>l.count-1 Then i := i
           Else i := i+1;
           //Down Key
           viewer_pos;
           viewer(title);
         End;
    #81:
         Begin
           If l.count<screenheight-3 Then i := 0
           Else
             Begin
               i := i + screenheight-3;
               If i > l.count -1 Then i := l.count -1 - screenheight-3;
             End;


           //              If i+((screenheight-3)*2)>l.count-1 Then i := l.count-screenheight-3
           //              Else i := i+((screenheight-3));
           //Page Down
           viewer_pos;
           viewer(title);
         End;
    #73:
         Begin
           If i-screenheight-2<1 Then i := 0
           Else i := i-screenheight-2;
           //Page Up
           viewer_pos;
           viewer(title);
         End;
    #27: back;
    //esc
    #13:
         Begin
           //process command
           baseline('Use Up,Down Arrow keys, Page Up/Down. Type ''help'' for available commands.');
           command(kbbuf);
           history.add(kbbuf);
           history_index := history.count;
           kbbuf := '';
         End;
    #32,#47,#48,#49,#50,#51,#52,#53,#54,#55,#56,#57:
                                                     Begin
                                                       Screen.WriteStr(ch);
                                                       kbbuf := kbbuf+ch;
                                                     End;
    #97,#98,#99,#100,#101,#102,#103,#104,#105,#106,#107,#108,#109,#110,#111,#112,#113,#114,#115,#116
    ,#117,#118,#119,#120,#121,#122:
                                    Begin
                                      Screen.WriteStr(ch);
                                      kbbuf := kbbuf+ch;
                                    End;
    //#65,#66,#67,#68,#69,#70,#71,#74,#76,#78,#79,#82,#83,#84,#85,#86,#87,#88,#89,#90:begin
    //	 Screen.WriteStr(ch);
    //     kbbuf:=kbbuf+ch;
    //     end;
  End;
Until leave=true;


End.
