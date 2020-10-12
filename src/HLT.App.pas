unit HLT.App;

{$IFDEF FPC}
  {$mode delphi}
{$ENDIF}


interface

uses
  SysUtils,
  JPL.Console, JPL.Console.ColorParser, JPL.ConsoleApp, JPL.CmdLineParser, JPL.TStr,
  HLT.Types;

type


  TApp = class(TJPConsoleApp)
  private
    AppParams: TAppParams;
    FDefaultColors: string;
  public
    procedure Init;
    procedure Run;

    procedure RegisterOptions;
    procedure ProcessOptions;

    procedure PerformMainAction;

    procedure DisplayHelpAndExit(const ExCode: integer);
    procedure DisplayShortUsageAndExit(const Msg: string; const ExCode: integer);
    procedure DisplayBannerAndExit(const ExCode: integer);
    procedure DisplayMessageAndExit(const Msg: string; const ExCode: integer);

    property DefaultColors: string read FDefaultColors;
  end;



implementation





{$region '                    Init                              '}

procedure TApp.Init;
const
  SEP_LINE = '-------------------------------------------------';
begin
  //----------------------------------------------------------------------------

  AppName := 'Highlight Text';
  MajorVersion := 1;
  MinorVersion := 0;
  Self.Date := EncodeDate(2020, 10, 13);
  FullNameFormat := '%AppName% %MajorVersion%.%MinorVersion% [%OSShort% %Bits%-bit] (%AppDate%)';
  Description := 'Highlights the given <color=yellow>substring</color> in the specified <color=cyan>text</color> with the specified color.';
  Author := 'Jacek Pazera';
  HomePage := 'https://www.pazera-software.com/products/highlight-text/';
  HelpPage := HomePage;

  LicenseName := 'Freeware, Open Source';
  License := 'This program is completely free. You can use it without any restrictions, also for commercial purposes.' + ENDL +
    'The program''s source files are available at https://github.com/jackdp/Highlight-Text' + ENDL +
    'Compiled binaries can be downloaded from ' + HomePage;

  TrimExtFromExeShortName := True;

  AppParams.Text := '';
  AppParams.AddLogHighlights := True;


  HintBackgroundColor := TConsole.clLightGrayBg;
  HintTextColor := TConsole.clBlackText;
  FDefaultColors := 'White,DarkMagenta';

  //-----------------------------------------------------------------------------

  TryHelpStr := ENDL + 'Try <color=white,black>' + ExeShortName + ' --help</color> for more information.';

  ShortUsageStr :=
    ENDL +
    'Usage: ' + ExeShortName +
    ' <color=cyan>TEXT</color> [-c=COLORS] [-s=1|0] [-t=<color=yellow>STR</color>] [-l] [-h] [-V] [--license] [--home]' + ENDL +
    ENDL +
    'Mandatory arguments to short options are mandatory for long options too.' + ENDL +
    'Options are case-sensitive. Options and values in square brackets are optional.' + ENDL +
    'You can use the <color=white,black>-t</color>, <color=white,black>-c</color>, and <color=white,black>-s</color> options multiple times.';



  ExtraInfoStr :=
    SEP_LINE + ENDL +
    '<color=cyan,black>TEXT</color>' + ENDL +
    'Text can be given on the command line or/and redirected from an external command via a pipe.' + ENDL +
    'You can provide multiple text values in any combination with the options.' + ENDL +

    SEP_LINE + ENDL +
    'AVAILABLE COLORS' + ENDL +
    '  <color=none,    Red>  </color> Red, LightRed            <color=none,DarkRed>  </color> DarkRed' + ENDL +
    '  <color=none,  Green>  </color> Green, LightGreen        <color=none,DarkGreen>  </color> DarkGreen' + ENDL +
    '  <color=none,   Blue>  </color> Blue, LightBlue          <color=none,DarkBlue>  </color> DarkBlue' + ENDL +
    '  <color=none,   Cyan>  </color> Cyan, LightCyan          <color=none,DarkCyan>  </color> DarkCyan' + ENDL +
    '  <color=none,Magenta>  </color> Magenta, LightMagenta    <color=none,DarkMagenta>  </color> DarkMagenta' + ENDL +
    '  <color=none, Yellow>  </color> Yellow, LightYellow      <color=none,DarkYellow>  </color> DarkYellow' + ENDL +
    '  <color=none,   Gray>  </color> Gray, LightGray          <color=none,DarkGray>  </color> DarkGray' + ENDL +
    '  <color=none,  White>  </color> White                    <color=none,Black>  </color> Black' + ENDL +
    '  Fuchsia = LightMagenta' + ENDL +
    '  Lime = LightGreen' + ENDl +
    'Color names are case insensitive.' +

    ENDL + SEP_LINE + ENDL +
    'EXIT CODES' + ENDL +
    '  ' + CON_EXIT_CODE_OK.ToString + ' - OK - no errors.' + ENDL +
    '  ' + CON_EXIT_CODE_SYNTAX_ERROR.ToString + ' - Syntax error.' + ENDL +
    '  ' + CON_EXIT_CODE_ERROR.ToString + ' - Other error.';

  ExamplesStr :=
    SEP_LINE + ENDL +
    'EXAMPLES' + ENDL +
    '  <color=white,black>Example 1</color>' + ENDL + '  Highlight the word "ipsum" and "amet" with the default colors:' + ENDL +
    '    ' + ExeShortName + ' "Lorem ipsum dolor sit amet..." -t ipsum -t amet' + ENDL +
    '  Result:' + ENDL +
    '    Lorem <color=' + FDefaultColors + '>ipsum</color> dolor sit <color=' +FDefaultColors + '>amet</color>...' + ENDL + ENDL +

    '  <color=white,black>Example 2</color>' + ENDL + '  Highlight the word "ipsum" with the red color, and word "dolor" with the lime color:' + ENDL +
    '    ' + ExeShortName + ' "Lorem ipsum dolor sit amet..." -c yellow,darkred -t ipsum -c black,lime -t dolor' + ENDL +
    '  Result:' + ENDL +
    '    Lorem <color=yellow,darkred>ipsum</color> <color=Black,LightGreen>dolor</color> sit amet...' + ENDL + ENDL +

    '  <color=white,black>Example 3</color>' + ENDL + '  Highlight the file extension ".txt" in the file list returned by the ' +
    '<color=white,black>dir</color> command:' + ENDL +
    '    dir | ' + ExeShortName + ' -c yellow -t .txt';

  //------------------------------------------------------------------------------


end;
{$endregion Init}


{$region '                    Run                               '}
procedure TApp.Run;
begin
  inherited;

  RegisterOptions;
  Cmd.Parse;
  ProcessOptions;
  if Terminated then Exit;

  PerformMainAction; // <----- the main procedure
end;
{$endregion Run}


{$region '                    RegisterOptions                   '}
procedure TApp.RegisterOptions;
const
  MAX_LINE_LEN = 110;
var
  Category: string;
begin

  Cmd.CommandLineParsingMode := cpmCustom;
  Cmd.UsageFormat := cufWget;
  Cmd.AcceptAllNonOptions := True; // All non-option params will be treated as the input text


  // ------------ Registering command-line options -----------------

  Category := 'info';
  Cmd.RegisterOption('t', 'highlight-text', cvtRequired, False, False, 'Text to be highlighted.', 'STR', Category);

  Cmd.RegisterOption('c', 'colors', cvtRequired, False, False,
    'The foreground and background color used to highlight the specified text. See the list of available colors below.',
    'FgColor[,BgColor]', Category);

  Cmd.RegisterOption('s', 'case-sensitive', cvtRequired, False, False,
    'Consider the character case when searching for the text to highlight. By default -s=0 (not case sensitive).', '1|0', Category);

  Cmd.RegisterOption('l', 'log-colors', cvtNone, False, False,
    'Highlight some special words used in the logs such as Error, Failed, Warning, Success etc.', '', Category);

  Cmd.RegisterOption('h', 'help', cvtNone, False, False, 'Show this help.', '', Category);
  Cmd.RegisterShortOption('?', cvtNone, False, True, '', '', '');
  Cmd.RegisterOption('V', 'version', cvtNone, False, False, 'Show application version.', '', Category);
  Cmd.RegisterLongOption('license', cvtNone, False, False, 'Display program license.', '', Category);
  Cmd.RegisterLongOption('home', cvtNone, False, False, 'Opens program home page in the default browser.', '', Category);

  UsageStr :=
    ENDL +
    'OPTIONS' + ENDL + Cmd.OptionsUsageStr('  ', 'info', MAX_LINE_LEN, '  ', 30);

end;
{$endregion RegisterOptions}


{$region '                    ProcessOptions                    '}
procedure TApp.ProcessOptions;
var
  i: integer;
  s: string;
begin

  // ---------------------------- Invalid options -----------------------------------

  if Cmd.ErrorCount > 0 then
  begin
    DisplayShortUsageAndExit(Cmd.ErrorsStr, TConsole.ExitCodeSyntaxError);
    Exit;
  end;


  // ---------------------------- Log colors -----------------------------------

  AppParams.AddLogHighlights := Cmd.IsOptionExists('log-colors');


  // ----------- Input redirected from the external command with the pipe -------------

  if TConsole.IsInputRedirected then
  while not EOF do
  begin
    Readln(s);
    AppParams.Text += s + ENDL;
  end;


  //------------------------------------ Help ---------------------------------------

  if (ParamCount = 0) or (Cmd.IsLongOptionExists('help')) or (Cmd.IsOptionExists('?')) then
  begin
    DisplayHelpAndExit(TConsole.ExitCodeOK);
    Exit;
  end;


  //---------------------------------- Home -----------------------------------------

  {$IFDEF MSWINDOWS}
  if Cmd.IsLongOptionExists('home') then
  begin
    GoToHomePage;
    Terminate;
    Exit;
  end;
  {$ENDIF}


  //------------------------------- Version ------------------------------------------

  if Cmd.IsOptionExists('version') then
  begin
    DisplayMessageAndExit(AppFullName, TConsole.ExitCodeOK);
    Exit;
  end;


  //------------------------------- Version ------------------------------------------

  if Cmd.IsLongOptionExists('license') then
  begin
    TConsole.WriteTaggedTextLine('<color=white,black>' + LicenseName + '</color>');
    DisplayLicense;
    Terminate;
    Exit;
  end;



  //---------------------------- Unknown Params --------------------------
  for i := 0 to Cmd.UnknownParamCount - 1 do
  begin
    AppParams.Text += StripQuotes(Cmd.UnknownParams[i].ParamStr);
  end;


  if AppParams.Text = '' then
  begin
    DisplayError('No input text was provided!');
    ExitCode := TConsole.ExitCodeError;
    Terminate;
    Exit;
  end;


end;

{$endregion ProcessOptions}




{$region '                    PerformMainAction                     '}
procedure TApp.PerformMainAction;
type
  TTextColorsRec = record
    Text: string;
    Colors: string;
    csMode: TConParCaseSensitiveMode;
  end;
var
  cc: TConColorParser;
  Param: TClpParam;
  i: integer;
  CurrentColors, OptName: string;
  Arr: array of TTextColorsRec;
  CSMode: TConParCaseSensitiveMode;

  procedure AddToArray(const s, ColorsStr: string; Mode: TConParCaseSensitiveMode);
  begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)].Text := s;
    Arr[High(Arr)].Colors := ColorsStr;
    Arr[High(Arr)].csMode := Mode;
  end;
begin
  if Terminated then Exit;
  if AppParams.Text = '' then Exit;

  if AppParams.AddLogHighlights then
  begin
    AddToArray('Error', 'White,LightRed', csmIgnoreCase);
    AddToArray('Failed', 'Red,Black', csmIgnoreCase);
    AddToArray('Fail', 'Red,Black', csmIgnoreCase);
    AddToArray('cannot', 'LightMagenta,Black', csmIgnoreCase);
    AddToArray('can''t', 'LightMagenta,Black', csmIgnoreCase);
    AddToArray('not found', 'LightMagenta,Black', csmIgnoreCase);
    AddToArray('Warning', 'LightYellow,Black', csmIgnoreCase);
    AddToArray('Success', 'LightGreen,Black', csmIgnoreCase);
  end;


  CurrentColors := FDefaultColors;
  CSMode := csmIgnoreCase;

  for i := 0 to Cmd.ParsedParamCount - 1 do
  begin
    Param := Cmd.ParsedParam[i];
    if not Param.Parsed then Continue;

    OptName := UpperCase(Param.OptionName);

    if (OptName = 'C') or (OptName = 'COLORS') then
    begin
      CurrentColors := StripQuotes(Param.OptionValue);
      CurrentColors := TStr.ReplaceAll(CurrentColors, 'Lime', 'LightGreen', True);
      CurrentColors := TStr.ReplaceAll(CurrentColors, 'Fuchsia', 'LightMagenta', True);
    end

    else if (OptName = 'T') or (OptName = 'HIGHLIGHT-TEXT') then
    begin
      AddToArray(StripQuotes(Param.OptionValue), CurrentColors, CSMode);
    end

    else if (OptName = 'S') or (OptName = 'CASE-SENSITIVE') then
    begin
      if Param.OptionValue = '1' then CSMode := csmCaseSensitive
      else if Param.OptionValue = '0' then CSMode := csmIgnoreCase
      else
      begin
        DisplayError('Invalid value for the "-s" option: ' + Param.OptionValue);
        DisplayTryHelp;
        ExitCode := TConsole.ExitCodeSyntaxError;
        Terminate;
        Break;
      end;
    end;
  end;

  if Terminated then Exit;

  cc := TConColorParser.Create;
  try
    cc.CaseSensitive := False;
    cc.Text := AppParams.Text;
    for i := 0 to High(Arr) do cc.AddHighlightedText(Arr[i].Text, Arr[i].Colors, Arr[i].csMode);
    cc.Parse;
    cc.WriteText;
  finally
    cc.Free;
  end;

end;
{$endregion PerformMainAction}


{$region '                    Display... procs                  '}
procedure TApp.DisplayHelpAndExit(const ExCode: integer);
begin
  DisplayBanner;
  DisplayShortUsage;
  DisplayUsage;
  DisplayExtraInfo;
  DisplayExamples;

  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayShortUsageAndExit(const Msg: string; const ExCode: integer);
begin
  if Msg <> '' then Writeln(Msg);
  DisplayShortUsage;
  DisplayTryHelp;
  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayBannerAndExit(const ExCode: integer);
begin
  DisplayBanner;
  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayMessageAndExit(const Msg: string; const ExCode: integer);
begin
  Writeln(Msg);
  ExitCode := ExCode;
  Terminate;
end;
{$endregion Display... procs}



end.
